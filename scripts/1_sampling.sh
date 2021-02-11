#!/usr/bin/env sh

# The script exits when a command fails or it uses undeclared variables
set -o errexit
set -o nounset


# shellcheck disable=SC1090
. "$(dirname "$0")/mlflow_funcs.sh"


# Argument parsing
while [ "$#" -gt 0 ]; do
    case $1 in
        -p|--project_path) project_path="$2";   shift  ;;
        -d|--data_file)    data_file="$2";      shift  ;;
        -i|--input_file)   input_file="$2";     shift  ;;
        -o|--output_dir)   output_dir="$2";     shift  ;;
        -a|--mlflow_args)  mlflow_args="$2";    shift  ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done


### IMPORTANT NOTE:
###
### When the MLFlow metrics / artifacts are stored locally, the provided MLFlow
### Tracking URI must be sanitized, to inject the WORKDIR value at the beginning.
###
### This is necessary to avoid file permission errors in REANA.
### Ref: https://github.com/scailfin/madminer-workflow/issues/40

if [ -n "${MLFLOW_TRACKING_URI:-}" ]; then
    uri="${MLFLOW_TRACKING_URI}"
    uri=$(sanitize_tracking_uri "${uri}" "${output_dir}")

    export MLFLOW_TRACKING_URI=${uri}
fi


# Prepare MLFlow optional arguments
mlflow_parsed_args=$(parse_mlflow_args "${mlflow_args:-}")

eval mlflow run \
    --experiment-name "madminer-ml-sample" \
    --entry-point "sample" \
    --backend "local" \
    --no-conda \
    --param-list "project_path=${project_path}" \
    --param-list "data_file=${data_file}" \
    --param-list "inputs_file=${input_file}" \
    --param-list "output_folder=${output_dir}" \
    "${mlflow_parsed_args}" \
    "${project_path}"
