#!/usr/bin/env bash
# A `cpp -P`-compatible preprocessor for Makefiles, using `lfortran -E`
# (which writes to stdout and does not accept -P). Used on Windows, which
# has no `cpp`.
args=()
for a in "$@"; do
    [[ "$a" == "-P" ]] || args+=("$a")
done
exec lfortran -E "${args[@]}"
