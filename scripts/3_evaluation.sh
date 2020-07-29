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
        -m|--model_file)   model_file="$2";     shift  ;;
        -o|--output_dir)   output_dir="$2";     shift  ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done


# Define auxiliary variables
MODELS_ABS_PATH="${output_dir}/models"
RATES_ABS_PATH="${output_dir}/rates"
RESULTS_ABS_PATH="${output_dir}/results"
TESTS_ABS_PATH="${output_dir}/test"


# Cleanup previous files (useful when run locally)
rm -rf "${RESULTS_ABS_PATH}"
rm -rf "${TESTS_ABS_PATH}"

mkdir -p "${MODELS_ABS_PATH}"
mkdir -p "${RATES_ABS_PATH}"
mkdir -p "${RESULTS_ABS_PATH}"
mkdir -p "${TESTS_ABS_PATH}"


# Unzip the models folder contents to identify the model
tar -xvf "${model_file}" -C "${MODELS_ABS_PATH}"

MODEL_NAME=$(find "${MODELS_ABS_PATH}" -type d -mindepth 1 -maxdepth 1 -exec basename {} \;)
MODEL_DIR="${MODELS_ABS_PATH}/${MODEL_NAME}"


# Perform actions
mlflow run \
    --experiment-name "madminer-ml-eval" \
    --entry-point "eval" \
    --backend "local" \
    --no-conda \
    --param-list "project_path=${project_path}" \
    --param-list "data_file=${data_file}" \
    --param-list "eval_folder=${MODEL_DIR}" \
    --param-list "inputs_file=${input_file}" \
    --param-list "output_folder=${output_dir}" \
    "${project_path}"

tar -czf "${output_dir}/Results_${MODEL_NAME}.tar.gz" \
    -C "${output_dir}" \
    "models" \
    "rates" \
    "results" \
    "test"
