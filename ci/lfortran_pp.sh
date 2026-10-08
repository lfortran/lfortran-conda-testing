#!/usr/bin/env bash
# A `cpp -P`-compatible preprocessor for Makefiles, using `lfortran -E`
# (which writes to stdout and does not accept -P). Used on Windows, which
# has no `cpp`. On Windows `lfortran -E` writes CRLF line endings; convert
# them to LF to avoid https://github.com/lfortran/lfortran/issues/14168.
set -o pipefail
args=()
for a in "$@"; do
    [[ "$a" == "-P" ]] || args+=("$a")
done
lfortran -E "${args[@]}" | tr -d '\r'
