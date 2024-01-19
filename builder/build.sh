#!/bin/bash -e

find ./output/ -type f -exec rm {} \;

./builder/builder

find ./output/ -maxdepth 1 -type f -iname '*.tex' | while read -r __file; do
    tectonic --color 'always' --outdir './output/' "${__file}"
done

exit
