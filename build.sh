#!/bin/bash -e

./builder/builder

cd output

find . -maxdepth 1 -type f -iname '*.tex' | while read -r __file; do
    tectonic --color 'always' --outdir './' "${__file}"
done

cd ../

exit
