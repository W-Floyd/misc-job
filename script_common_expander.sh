#!/bin/bash

__loop_limit='100'

declare -A __lookup

while read -r __filename; do

    __name="${__filename#*_}"
    __name="${__name%.*}"

    __lookup[${__name}]="$(cat "${__filename}")"

done < <(find . -maxdepth 1 -type f -iname 'snippet_*')

while read -r __filename; do

    echo "  Filling: ${__filename#./}"

    __loop_fail='0'

    __contents="$(cat "${__filename}")"

    __md5sum="$(md5sum <<<"${__contents}")"
    __length="$(wc -c <<<"${__contents}")"
    __old_md5sum=''
    __old_length='0'

    __n='0'

    __continue='1'

    while [ "${__continue}" == '1' ]; do

        for __variable in "${!__lookup[@]}"; do

            __replacement="${__lookup[$__variable]}"

            __contents="$(

                while IFS= read -r __line; do

                    if [[ "${__line}" == *"{{${__variable}}}"* ]]; then
                        echo "${__line/\{\{${__variable}\}\}*/}"
                        echo "${__replacement}"
                        echo "${__line#*\{\{${__variable}\}\}}"
                    else
                        echo "${__line}"
                    fi

                done <<<"${__contents}"

            )"

        done

        __n=$((__n + 1))

        if [ "${__n}" -gt "${__loop_limit}" ]; then
            echo "More than ${__loop_limit} iterations, assuming this is a loop!"
            __loop_fail='1'
            break
        fi

        __old_length="${__length}"
        __length="$(wc -c <<<"${__contents}")"

        if ! [ "${__old_length}" -lt "${__length}" ]; then
            __old_md5sum="${__md5sum}"
            __md5sum="$(md5sum <<<"${__contents}")"

            if [[ "${__old_md5sum}" == "${__md5sum}" ]]; then
                __continue='0'
            fi

        fi

    done

    if [ "${__loop_fail}" == '0' ]; then
        __output="./${__filename#*_}"
        echo "${__output}" >>'.gitignore'
        echo "${__contents}" >"${__output}"
    fi

done < <(find . -maxdepth 1 -type f -iname 'partial_*')

exit
