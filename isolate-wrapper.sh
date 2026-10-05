#!/bin/bash
new_args=()
meta_file=""
for arg in "$@"; do
    if [[ "$arg" != "--cg" && "$arg" != "--cg-timing" && "$arg" != --cg-mem=* ]]; then
        new_args+=("$arg")
    fi
    if [[ "$arg" == -M* ]]; then
        meta_file="${arg#-M}"
    elif [[ "$arg" == --meta=* ]]; then
        meta_file="${arg#--meta=}"
    fi
done
/judgels/isolate/bin/isolate.real "${new_args[@]}"
exit_code=$?

if [[ -n "$meta_file" && -f "$meta_file" ]]; then
    if ! grep -q "^cg-mem:" "$meta_file"; then
        rss=$(grep "^max-rss:" "$meta_file" | cut -d: -f2)
        if [[ -n "$rss" ]]; then
            echo "cg-mem:$rss" >> "$meta_file"
        else
            echo "cg-mem:0" >> "$meta_file"
        fi
    fi
fi

exit $exit_code
