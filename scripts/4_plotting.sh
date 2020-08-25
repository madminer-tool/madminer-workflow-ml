#!/usr/bin/env sh

# The script exits when a command fails or it uses undeclared variables
set -o errexit
set -o nounset


# Argument parsing
while [ "$#" -gt 0 ]; do
    case $1 in
        -p|--project_path) project_path="$2";   shift  ;;
        -i|--input_file)   input_file="$2";     shift  ;;
        -r|--result_files) result_files="$2";   shift  ;;
        -o|--output_dir)   output_dir="$2";     shift  ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done


# Perform actions
mkdir -p "${output_dir}/plots"

# POSIX shell scripts do not allow arrays (workaround)
echo "${result_files}" | tr ' ' '\n' | while read -r file; do
    tar -xf "${file}" -C "${output_dir}";
done


python3 "${project_path}/code/plotting.py" "${input_file}" "${output_dir}"
