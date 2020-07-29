#!/usr/bin/env sh

# The script exits when a command fails or it uses undeclared variables
set -o errexit
set -o nounset


# Define help function
helpFunction()
{
    printf "\n"
    printf "Usage: %s -p project_path -d data_file -i input_file -o output_dir\n" "${0}"
    printf "\t-p Project top-level path\n"
    printf "\t-d Data file path\n"
    printf "\t-i Workflow input file\n"
    printf "\t-o Workflow output dir\n"
    exit 1
}

# Argument parsing
while getopts "p:d:i:o:" opt
do
    case "$opt" in
        p ) PROJECT_PATH="$OPTARG" ;;
        d ) DATA_FILE="$OPTARG" ;;
        i ) INPUT_FILE="$OPTARG" ;;
        o ) OUTPUT_DIR="$OPTARG" ;;
        ? ) helpFunction ;;
    esac
done

if [ -z "${PROJECT_PATH}" ] || [ -z "${DATA_FILE}" ] || [ -z "${INPUT_FILE}" ] || [ -z "${OUTPUT_DIR}" ]
then
    echo "Some or all of the parameters are empty";
    helpFunction
fi


# Perform actions
mlflow run \
    --experiment-name "madminer-ml-sample" \
    --entry-point "sample" \
    --backend "local" \
    --no-conda \
    --param-list "project_path=${PROJECT_PATH}" \
    --param-list "data_file=${DATA_FILE}" \
    --param-list "inputs_file=${INPUT_FILE}" \
    --param-list "output_folder=${OUTPUT_DIR}" \
    "${PROJECT_PATH}"
