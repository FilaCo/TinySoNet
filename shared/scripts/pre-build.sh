#!/usr/bin/env bash

set -euo pipefail

source ./scripts/utils.sh

# $1 - target triple
# $2 - profile
copy_objc_libs_for_profile() {
    local cangjie_modules_dir
    cangjie_modules_dir="$(cangjie_modules_dir_for $1)"
    local target_dir
    # TODO: $PWD is probably not a good idea
    target_dir="$PWD"/target/"$1"/"$2"/objc

    mkdir -p "$target_dir"
    cp "$cangjie_modules_dir"/objc.* "$target_dir"/
}

copy_objc_libs() {
    # hope one day we will get a build profile from build.cj
    copy_objc_libs_for_profile "$1" debug
    copy_objc_libs_for_profile "$1" release
}

copy_libs() {
    local target_interop_lang
    target_interop_lang="$(target_interop_lang_for $1)"
    case "$target_interop_lang" in
        objc) copy_objc_libs "$1" ;;
        *) return 1 ;;
    esac
}

generate_objc_mirrors() {
    local sdk
    sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
    local res_dir
    res_dir="$(xcrun --sdk iphonesimulator clang -print-resource-dir)"
    local clang_target_triple
    clang_target_triple="$(clang_target_triple_for $1)"

    local toml
    toml="$(mktemp -t ObjCInteropGen).toml"
    # TODO: $PWD is probably not a good idea 
    sed -e "s|@SDK@|$sdk|g" -e "s|@RES_DIR@|$res_dir|g" \
        -e "s|@CLANG_TRIPLE@|$clang_target_triple|g" \
        -e "s|@OUTPUT_PATH@|$PWD/src/objc/foundation|g" \
        "./ObjCInteropGen.toml.in" > "$toml"
    ObjCInteropGen "$toml" 2>&1 | grep -vE "unsupported feature" || true
    rm -f "$toml"
}

generate_mirrors() {
    local target_interop_lang
    target_interop_lang="$(target_interop_lang_for $1)"
    case "$target_interop_lang" in
        objc) generate_objc_mirrors "$1" ;;
        *) return 1 ;;
    esac
}

main() {
    copy_libs "$@"
    generate_mirrors "$@"
}

main "$@"