#!/bin/bash

__output_dir='output'

if [ -e '.gitignore' ]; then
    rm '.gitignore'
fi

touch '.gitignore'

################################################################################

while read -r __progname; do
    if ! which "${__progname}" &>/dev/null; then
        echo "Missing '${__progname}'"
        cat '.gitignore_persist' >>'.gitignore'
        exit
    fi
done <<<'j2'

################################################################################

while read -r __dirname; do
    if [ -d "${__dirname}" ]; then
        # rm -r "${__dirname}/"*
        true
    else
        mkdir "${__dirname}"
    fi
done <<<"${__output_dir}"

################################################################################

__cleanup() {
    if [ -d '__pycache__' ]; then
        rm -r '__pycache__'
    fi

    while read -r __file; do
        rm "${__file}"
    done <'.gitignore'

    cat '.gitignore_persist' >>'.gitignore'

    sort '.gitignore' | uniq >'.gitignore2'
    mv '.gitignore2' '.gitignore'

    find . | while read -r __file; do
        chown '1000:1000' "${__file}"
    done

}

__latex_build() {
    tectonic --color 'always' --outdir './' ${1}
}

__build() {
    __config="${1}"
    __template="${2}"
    __extension="${__template//*\./}"
    __output_template="${3}.${__extension}"
    __tmpdir="$(mktemp -d -p './')"

    j2 --undefined --customize './.customize.py' "${__template}" "${__config}" >"${__tmpdir}/${__output_template}"

    cp -r 'assets' "${__tmpdir}/assets"

    cd "${__tmpdir}" || {
        echo 'Temporary directory does not exist!'
        exit
    }

    echo "Rendering: ${__output_template}"

    case "${__extension}" in
    tex)
        __latex_build "${__output_template}"
        ;;
    *)
        echo "Unsupported format for rendering: ${__extension}"
        ;;
    esac

    while read -r __file; do
        mv "${__file}" "../${__output_dir}/${__file#\./}"
    done < <(find . -type d -path './assets' -prune -o -type f -print)

    cd ../

    rm -r "${__tmpdir}"

}

################################################################################

while read -r __script; do
    "${__script}"
done < <(find './' -maxdepth 1 -type f -not -name 'build.sh' -iname '*.sh' | grep -Fxvf './script_list')

while read -r __script; do
    "${__script}"
done <'./script_list'

################################################################################

__filenames="$(
    find . -maxdepth 1 -type f | while read -r __line; do
        echo "${__line#\./*}"
    done
)"

__configs="$(grep -E '^config_.*\.yaml$' <<<"${__filenames}")"

if [ "${#}" -gt 0 ]; then
    __configs=''
    until [ "${#}" == 0 ]; do
        if [ -e "${1}" ]; then
            __configs="$(sed -e 's|^\./||' -e 's|^partial_||' <<<"${1}")
${__configs}"
            echo "Using file '${1}'"
        else
            echo "File '${1}' does not exist!"
            __cleanup
            exit
        fi
        shift
    done
    __configs="$(sed -e '/^$/d' <<<"${__configs}")"
fi

__templates="$(grep -E '^template_.*' <<<"${__filenames}")"

while read -r __config; do
    IFS="_" read -r -a __config_name_parts <<<"${__config%\.*}"
    while read -r __template; do
        IFS="_" read -r -a __template_name_parts <<<"${__template%\.*}"
        if [ "${__template_name_parts[1]}" == "${__config_name_parts[1]}" ]; then
            __output_name="${__config_name_parts[1]}"
            if ! [ -z "${__config_name_parts[2]}" ]; then
                __output_name="${__output_name}_${__config_name_parts[2]}"
            fi
            if ! [ -z "${__template_name_parts[2]}" ]; then
                __output_name="${__output_name}_${__template_name_parts[2]}"
            fi
            __build "${__config}" "${__template}" "${__output_name}"
        fi
    done <<<"${__templates}"
done <<<"${__configs}"

if [ -e './output/resume.pdf' ]; then
    if [ -e './output/William Floyd - BSME.pdf' ]; then
        rm './output/William Floyd - BSME.pdf'
    fi
    cp './output/resume.pdf' './output/William Floyd - BSME.pdf'
fi

__cleanup

exit
