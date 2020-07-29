#!/usr/bin/env sh

# The script exits when a command fails or it uses undeclared variables
set -o errexit
set -o nounset


# Argument parsing
while [ "$#" -gt 0 ]; do
    case $1 in
        -p|--project_path) project_path="$2";   shift  ;;
        -d|--data_file)    data_file="$2";      shift  ;;
        -i|--input_file)   input_file="$2";     shift  ;;
        -o|--output_dir)   output_dir="$2";     shift  ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done


# Perform actions
mlflow run \
    --experiment-name "madminer-ml-sample" \
    --entry-point "sample" \
    --backend "local" \
    --no-conda \
    --param-list "project_path=${project_path}" \
    --param-list "data_file=${data_file}" \
    --param-list "inputs_file=${input_file}" \
    --param-list "output_folder=${output_dir}" \
    "${project_path}"
