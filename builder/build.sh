#!/bin/bash -e

find ./output/ -type f -exec rm {} \;

./builder/builder "${@}"

# CMap errors are for FontAwesome, where it makes no sense to map an icon to a copy-paste text
__ignored_texts='Creating ToUnicode CMap failed for
Failed to load ToUnicode CMap for font'

find ./output/ -maxdepth 1 -type f -iname '*.tex' | while read -r __file; do
    echo "Building ${__file}"
    tectonic --color 'always' --outdir './output/' "${__file}" |& while read -r __line; do
        grep -Fq -f <(echo "${__ignored_texts}") <<<"${__line}" || echo "${__line}"
    done
done

exit
