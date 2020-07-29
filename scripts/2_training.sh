#!/usr/bin/env sh

# The script exits when a command fails or it uses undeclared variables
set -o errexit
set -o nounset


# Argument parsing
while [ "$#" -gt 0 ]; do
    case $1 in
        -p|--project_path) project_path="$2";   shift  ;;
        -t|--train_folder) train_folder="$2";   shift  ;;
        -o|--output_dir)   output_dir="$2";     shift  ;;
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


# Perform actions
mlflow run \
    --experiment-name "madminer-ml-train" \
    --entry-point "train" \
    --backend "local" \
    --no-conda \
    --param-list "project_path=${project_path}" \
    --param-list "output_folder=${output_dir}" \
    --param-list "train_folder=${train_folder}" \
    "${project_path}"

tar -czvf "${MODEL_FILE_ABS_PATH}" -C "${MODEL_INFO_ABS_PATH}" .
