#!/bin/bash -e

__output_dir='./output/'

__tectonic='tectonic'

if [ -e './tectonic' ]; then
    __tectonic='./tectonic'
fi

if ! [ -d "${__output_dir}" ]; then
    mkdir "${__output_dir}"
fi
find "${__output_dir}" -type f -exec rm {} \;

./builder/builder "${@}"

# CMap errors are for FontAwesome, where it makes no sense to map an icon to a copy-paste text
__ignored_texts='Creating ToUnicode CMap failed for
Failed to load ToUnicode CMap for font'

find "${__output_dir}" -maxdepth 1 -type f -iname '*.tex' | while read -r __file; do
    echo "Building ${__file}"
    "${__tectonic}" --color 'always' --outdir "${__output_dir}" "${__file}" |& while read -r __line; do
        grep -Fq -f <(echo "${__ignored_texts}") <<<"${__line}" || echo "${__line}"
    done
done

exit
