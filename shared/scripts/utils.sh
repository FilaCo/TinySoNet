#!/usr/bin/env bash

# This script is designed to be sourced, e.g. `source utils.sh`

MODULE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# cjpm doesn't tell a build script the profile.
BUILD_PROFILES=(debug release)

# Every triple cjpm.toml configures. cjpm checks the bin-dependencies paths of
# the host target too, not only of the one being built, so the directories they
# name have to exist whichever target the build is for.
SUPPORTED_TARGETS=(aarch64-apple-ios-simulator aarch64-apple-darwin)

die() {
    printf '%s\n' "$*" >&2
    exit 1
}

target_interop_lang_for() {
    case "$1" in
        *apple*) echo "objc" ;;
        *)                           return 1 ;;
    esac
}

# $1 - target triple
cangjie_slice_for() {
    case "$1" in
        aarch64-apple-ios-simulator) echo "ios_simulator_aarch64_cjnative" ;;
        aarch64-apple-ios)           echo "ios_aarch64_cjnative" ;;
        aarch64-apple-darwin)        echo "darwin_aarch64_cjnative" ;;
        *)                           return 1 ;;
    esac
}

# $1 - target triple
cangjie_modules_dir_for() {
    echo "$CANGJIE_HOME/modules/$(cangjie_slice_for "$1")"
}

# $1 - target triple
cangjie_lib_dir_for() {
    echo "$CANGJIE_HOME/lib/$(cangjie_slice_for "$1")"
}

# A build for the compiler's own target is a host build, which cjpm lays out
# differently from a cross build.
HOST_TARGET="$(cjc --version | sed -n 's/^Target: //p')" \
    || die "cannot ask cjc for its target; is the Cangjie environment set up?"
# sed reports success whether or not it matched, so an empty result means cjc
# printed something this does not recognise. Left empty it would silently make
# every target look like a cross build and quietly misplace the output.
[ -n "$HOST_TARGET" ] || die "cjc --version reported no 'Target:' line"

is_host_target() {
    [ "$1" = "$HOST_TARGET" ]
}

# cjpm drops the host target's output straight into target/<profile> and every
# other target's into target/<triple>/<profile>.
# $1 - target triple
# $2 - profile
cjpm_output_dir_for() {
    if is_host_target "$1"; then
        echo "$MODULE_ROOT/target/$2"
    else
        echo "$MODULE_ROOT/target/$1/$2"
    fi
}

# ---------------------------------------------------------------------------
# ObjC / Apple
# ---------------------------------------------------------------------------

IOS_MIN_VERSION="${TSN_BUILD_IOS_MIN_VERSION:-17.0}"
MACOS_MIN_VERSION="${TSN_BUILD_MACOS_MIN_VERSION:-14.0}"

# Must match the module name in native/objc/support/module.modulemap.
KIT_NAME="TinySoNetKit"

# Where the Apple app links the kit from. Inside the build tree the xcframework
# sits under a path that spells out the triple and the profile, and an Xcode file
# reference cannot follow that, so the finished kit is published to one fixed
# place next to the app project.
APPLE_KIT_DIR="${TSN_BUILD_APPLE_KIT_DIR:-$MODULE_ROOT/../appleApp/Frameworks}"

# Where cjc writes the ObjC half of @ObjCImpl. cjpm.toml names the same path in
# --objc-interop-output-dirю
OBJC_GEN_DIR="$MODULE_ROOT/native/objc/generated"

# Headers and module map cjc does not generate but its output needs.
OBJC_SUPPORT_DIR="$MODULE_ROOT/native/objc/support"

OBJC_MIRRORS_DIR="$MODULE_ROOT/src/objc/foundation"
OBJC_MIRRORS_PACKAGE="tsn.objc.foundation"

OBJC_MIRROR_OS=(iOS macOS)

objc_mirror_target_for() {
    case "$1" in
        iOS)   echo "aarch64-apple-ios-simulator" ;;
        macOS) echo "aarch64-apple-darwin" ;;
        *)     return 1 ;;
    esac
}

objc_mirror_package_for() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}


# pre-build stamps this the moment a build starts, so post-build can tell what
# the run it belongs to actually produced from what an earlier run left behind.
BUILD_MARKER="$MODULE_ROOT/target/.build-started"

mark_build_started() {
    mkdir -p "$(dirname "$BUILD_MARKER")"
    : > "$BUILD_MARKER"
}

# Whether the packages in $1 were compiled by the run in progress. cjpm builds
# one profile at a time and never says which, so this is how the other one is
# recognised and left alone.
# $1 - directory holding a profile's compiled packages
built_in_this_run() {
    [ -e "$BUILD_MARKER" ] || return 1

    local archive
    for archive in "$1"/*.a; do
        [ -e "$archive" ] || continue
        if [ "$archive" -nt "$BUILD_MARKER" ]; then
            return 0
        fi
    done
    return 1
}

# Whether $1 was built from the sources as they stand. A slice older than any of
# them was compiled from code that has since changed.
# $1 - a slice's static library
kit_slice_is_current() {
    [ -e "$1" ] || return 1
    local newer
    newer="$(find "$MODULE_ROOT/src" "$OBJC_SUPPORT_DIR" -type f -newer "$1" -print -quit)"
    [ -z "$newer" ]
}

# Whether the kit carries the Cangjie runtime itself. With it off the host has to
# put the same archives on the link line from somewhere else.
BUNDLE_RUNTIME="${TSN_BUILD_BUNDLE_RUNTIME:-1}"

clang_target_triple_for() {
    case "$1" in
        aarch64-apple-ios-simulator) echo "arm64-apple-ios$IOS_MIN_VERSION-simulator" ;;
        aarch64-apple-darwin)        echo "arm64-apple-macos$MACOS_MIN_VERSION" ;;
        *)                           return 1 ;;
    esac
}

# $1 - target triple, matched the same way the rest of this file matches them
objc_target_is_macos() {
    case "$1" in
        *-darwin) return 0 ;;
        *)        return 1 ;;
    esac
}

# TargetConditionals.h recognises only the iOS family through the __is_target_os
# builtins; macOS is left to a legacy branch that wants __APPLE_CC__, which the
# generator's clang does not define. So it reports neither platform, Foundation
# skips its <objc/NSObjCRuntime.h> include and NSInteger disappears. Saying which
# platform this is outright brings it back, and TARGET_OS_OSX is the only macro
# that falls out: checked against clang, the other thirteen of the family already
# agree. The iOS *simulator* needs nothing — its branch sets the whole family.
# The iOS device SDK fails exactly like macOS and wants -DTARGET_OS_IPHONE=1,
# which is one reason iOS mirrors are read through the simulator SDK: its
# headers produce identical mirrors without the override.
objc_extra_clang_args_for() {
    if objc_target_is_macos "$1"; then
        echo ', "-DTARGET_OS_OSX=1"'
    else
        echo ""
    fi
}

arch_for() {
    case "$1" in
        aarch64-*) echo "arm64" ;;
        *)                           return 1 ;;
    esac
}

sdk_for() {
    case "$1" in
        *-simulator) echo "iphonesimulator" ;;
        *-darwin)    echo "macosx" ;;
        *)                           return 1 ;;
    esac
}
