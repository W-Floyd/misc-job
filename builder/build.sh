#!/bin/bash -e

find ./output/ -type f -exec rm {} \;

./builder/builder "${@}"

__ignored_texts=(
    # CMap errors are for FontAwesome, where it makes no sense to map an icon to a copy-paste text
    'Creating ToUnicode CMap failed for'
    'Failed to load ToUnicode CMap for font'
)

find ./output/ -maxdepth 1 -type f -iname '*.tex' | while read -r __file; do
    echo "Building ${__file}"
    tectonic --color 'always' --outdir './output/' "${__file}" |& while read -r __line; do
        __found='0'
        for __ignore_text in ${__ignored_texts[@]}; do
            if grep -vq "${__ignore_text}" <<<"${__line}"; then
                __found='1'
                break
            fi
        done
        if [ "${__found}" == '0' ]; then
            echo "${__line}"
        fi
    done
done

exit
