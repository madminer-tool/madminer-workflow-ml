#!/usr/bin/env sh

# The script exits when a command fails or it uses undeclared variables
set -o errexit
set -o nounset


# Define help function
helpFunction()
{
    printf "\n"
    printf "Usage: %s -p project_path -t train_folder -o output_dir\n" "${0}"
    printf "\t-p Project top-level path\n"
    printf "\t-t Train folder path\n"
    printf "\t-o Workflow output dir\n"
    exit 1
}

# Argument parsing
while getopts "p:t:o:" opt
do
    case "$opt" in
        p ) PROJECT_PATH="$OPTARG" ;;
        t ) TRAIN_FOLDER="$OPTARG" ;;
        o ) OUTPUT_DIR="$OPTARG" ;;
        ? ) helpFunction ;;
    esac
done

if [ -z "${PROJECT_PATH}" ] || [ -z "${TRAIN_FOLDER}" ] || [ -z "${OUTPUT_DIR}" ]
then
    echo "Some or all of the parameters are empty";
    helpFunction
fi


# Define auxiliary variables
MODEL_FILE_ABS_PATH="${OUTPUT_DIR}/Model.tar.gz"
MODEL_INFO_ABS_PATH="${OUTPUT_DIR}/models"


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
    --param-list "project_path=${PROJECT_PATH}" \
    --param-list "output_folder=${OUTPUT_DIR}" \
    --param-list "train_folder=${TRAIN_FOLDER}" \
    "${PROJECT_PATH}"

tar -czvf "${MODEL_FILE_ABS_PATH}" -C "${MODEL_INFO_ABS_PATH}" .
