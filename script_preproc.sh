#!/bin/bash

# Preprocessor, used to match <<>> in pre_* files that are meant to improve readability
# Basically squashes whitespace that improves source readability but conflicts with LaTeX spaces.

while read -r __filename; do
    __v="${__filename}"
    __v="${__v/.\/pre_/}"
    sed -z \
        -e 's#\(\n\| \|\t\)*<<>>\(\n\| \|\t\)*##g' \
        -e 's#\(\n\| \|\t\)*<<n>>\(\n\| \|\t\)*#\n\n#g' \
        <"${__filename}" >"${__v}"
    echo "./${__v}" >>'.gitignore'
done < <(find './' -type f -iname 'pre_*')

exit
