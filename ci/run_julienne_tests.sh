#!/usr/bin/env bash
# Run a command, tee its output to a log and check the Julienne test summary
# ("_____ N of M tests passed. K tests were skipped _____") for failures.
#
# Usage: ci/run_julienne_tests.sh <command> [args...]
#
# This is needed for multi-image (coarray) runs: LFortran does not yet lower
# `error stop` to `prif_error_stop` (lfortran/lfortran#12326), so a failing
# test can still exit with status 0 under Caffeine.
set -uo pipefail

log=$(mktemp)
"$@" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
if [[ $status -ne 0 ]]; then
    echo "ERROR: '$*' exited with status $status"
    exit $status
fi

summary=$(grep -E "[0-9]+ of [0-9]+ tests passed" "$log" | tail -n 1)
rm -f "$log"
if [[ -z "$summary" ]]; then
    echo "ERROR: no Julienne test summary found in the output"
    exit 1
fi
if [[ ! "$summary" =~ ([0-9]+)\ of\ ([0-9]+)\ tests\ passed\.\ ([0-9]+)\ tests?\ (was|were)\ skipped ]]; then
    echo "ERROR: cannot parse Julienne test summary: $summary"
    exit 1
fi
passed=${BASH_REMATCH[1]}
total=${BASH_REMATCH[2]}
skipped=${BASH_REMATCH[3]}
if [[ $total -eq 0 || $((passed + skipped)) -ne $total ]]; then
    echo "ERROR: $((total - passed - skipped)) of $total tests failed"
    exit 1
fi
echo "OK: $passed of $total tests passed, $skipped skipped"
