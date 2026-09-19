#!/usr/bin/env bash
set -euo pipefail

source ./scripts/utils.sh

package_xc_framework() {
    
}

package_platform_artifact() {
    local target_interop_lang
    target_interop_lang="$(target_interop_lang_for $1)"
    case "$target_interop_lang" in
        objc) package_xc_framework "$1" ;;
        *) return 1 ;;
    esac
}

main() {
    package_platform_artifact "$1"
}

main "$@"