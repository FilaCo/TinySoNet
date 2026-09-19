#!/usr/bin/env bash

# This script is designed to be sourced, e.g. `source utils.sh`
IOS_MIN_VERSION="${TSN_BUILD_IOS_MIN_VERSION:-17.0}"

target_interop_lang_for() {
    case "$1" in
        *apple*) echo "objc" ;;
        *)                           return 1 ;;
    esac
}

cangjie_modules_dir_for() {
    case "$1" in
        aarch64-apple-ios-simulator) echo "$CANGJIE_HOME/modules/ios_simulator_aarch64_cjnative" ;;
        *)                           return 1 ;;
    esac
}

clang_target_triple_for() {
    case "$1" in
        aarch64-apple-ios-simulator) echo "arm64-apple-ios$IOS_MIN_VERSION-simulator" ;;
        *)                           return 1 ;;
    esac
}
