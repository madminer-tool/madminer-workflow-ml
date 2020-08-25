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
        -t|--train_folder) train_folder="$2";   shift  ;;
        -o|--output_dir)   output_dir="$2";     shift  ;;
        -a|--mlflow_args)  mlflow_args="$2";    shift  ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done


# Define auxiliary variables
MODEL_FILE_ABS_PATH="${output_dir}/Model.tar.gz"
MODEL_INFO_ABS_PATH="${output_dir}/models"


# Cleanup previous files (useful when run locally)
rm -rf "${MODEL_FILE_ABS_PATH}"
rm -rf "${MODEL_INFO_ABS_PATH}"

mkdir -p "${MODEL_INFO_ABS_PATH}"


# Prepare MLFlow optional arguments
mlflow_parsed_args=$(parse_mlflow_args "${mlflow_args:-}")


# Perform actions
eval mlflow run \
    --experiment-name "madminer-ml-train" \
    --entry-point "train" \
    --backend "local" \
    --no-conda \
    --param-list "project_path=${project_path}" \
    --param-list "output_folder=${output_dir}" \
    --param-list "train_folder=${train_folder}" \
    "${mlflow_parsed_args}" \
    "${project_path}"

tar -czvf "${MODEL_FILE_ABS_PATH}" -C "${MODEL_INFO_ABS_PATH}" .
