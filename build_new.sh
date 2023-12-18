#!/bin/bash -e

cd builder
./builder

cd output

find . -maxdepth 1 -type f -iname '*.tex' | while read -r __file; do
    # perl -i -p -e 'BEGIN{undef $/;} s/\{(\n|\s)+\n/{\n/g;' -e 'BEGIN{undef $/;} s/\n(\n|\s)+\}/\n\}/g;' "${__file}"
    tectonic --color 'always' --outdir './' "${__file}"
done

find . -maxdepth 1 -type f | while read -r __file; do
    mv "${__file}" ../../output/
done

cd ../
cd ../

exit
