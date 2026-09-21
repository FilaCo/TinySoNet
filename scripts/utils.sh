#!/usr/bin/env bash

# This script is designed to be sourced, e.g. `source utils.sh`

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

# cjpm drops the host target's packages straight into target/<profile> and every
# other target's into target/<triple>/<profile>.
# $1 - target triple
# $2 - profile
package_output_dir_for() {
    if is_host_target "$1"; then
        echo "$WORKSPACE_ROOT/target/$2"
    else
        echo "$WORKSPACE_ROOT/target/$1/$2"
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
APPLE_KIT_DIR="${TSN_BUILD_APPLE_KIT_DIR:-$WORKSPACE_ROOT/appleApp/Frameworks}"

# Where cjc writes the ObjC half of @ObjCImpl. cjpm.toml names the same path in
# --objc-interop-output-dir, relative to the directory the build was started
# from; pre-build makes the workspace's copy of that path lead here.
OBJC_GEN_DIR="$WORKSPACE_ROOT/shared/native/objc/generated"

# Headers and module map cjc does not generate but its output needs.
OBJC_SUPPORT_DIR="$WORKSPACE_ROOT/shared/native/objc/support"

OBJC_MIRRORS_DIR="$WORKSPACE_ROOT/shared/src/objc/foundation"
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


# The kit is ours rather than cjpm's, but it is built from that build's packages,
# so it keeps them company in the same profile directory.
# $1 - target triple
# $2 - profile
kit_slice_dir_for() {
    if is_host_target "$1"; then
        echo "$WORKSPACE_ROOT/target/$2/$KIT_NAME"
    else
        echo "$WORKSPACE_ROOT/target/$1/$2/$KIT_NAME"
    fi
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
