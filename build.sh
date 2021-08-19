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

__latex_build() {
    pdflatex -synctex=1 -interaction=nonstopmode \
        -output-directory='./' ${1} >/dev/null 2>&1
    find './' -maxdepth 1 -type f -not -name '*.pdf' -not -name '*.tex' -delete
}

__build() {
    __config="${1}"
    __template="${2}"
    __extension="${__template//*\./}"
    __output_template="${3}.${__extension}"
    __tmpdir="$(mktemp -d -p './')"

    j2 --undefined --customize './.customize.py' "${__template}" "${__config}" | (
        case "${__extension}" in
        tex)
            latexindent
            ;;
        *)
            cat
            ;;
        esac
    ) >"${__tmpdir}/${__output_template}"

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

__filenames="$(find . -maxdepth 1 -type f)"
__filenames2="$(
    while read -r __line; do
        echo "${__line#\./*}"
    done <<<"${__filenames}"
)"

__configs="$(grep -E '^config_.*\.yaml$' <<<"${__filenames2}")"
__templates="$(grep -E '^template_.*' <<<"${__filenames2}")"

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

if [ -d '__pycache__' ]; then
    rm -r '__pycache__'
fi

while read -r __file; do
    rm "${__file}"
done <'.gitignore'

cat '.gitignore_persist' >>'.gitignore'

sort '.gitignore' | uniq >'.gitignore2'
mv '.gitignore2' '.gitignore'

exit
