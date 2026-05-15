#!/bin/bash
set -euo pipefail

report="$1"

if [ ! -s "$report" ]; then
    echo "ERROR: report file is missing or empty at $report" >&2
    exit 1
fi

if ! grep -q "UnusedSymbol" "$report"; then
    echo "ERROR: report did not contain expected unused symbol 'UnusedSymbol'" >&2
    echo "--- report content ---" >&2
    cat "$report" >&2
    echo "--- end ---" >&2
    exit 1
fi
