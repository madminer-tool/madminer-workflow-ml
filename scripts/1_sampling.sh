#!/usr/bin/env sh

# The script exits when a command fails or it uses undeclared variables
set -o errexit
set -o nounset


# Define help function
helpFunction()
{
    printf "\n"
    printf "Usage: %s -p project_path -n num_train_samples -i input_file -d data_file -o output_dir\n" "${0}"
    printf "\t-p Project top-level path\n"
    printf "\t-n Number of training samples\n"
    printf "\t-i Workflow input file\n"
    printf "\t-d Data file path\n"
    printf "\t-o Workflow output dir\n"
    exit 1
}

# Argument parsing
while getopts "p:n:i:d:o:" opt
do
    case "$opt" in
        p ) PROJECT_PATH="$OPTARG" ;;
        n ) NUM_SAMPLES="$OPTARG" ;;
        i ) INPUT_FILE="$OPTARG" ;;
        d ) DATA_FILE="$OPTARG" ;;
        o ) OUTPUT_DIR="$OPTARG" ;;
        ? ) helpFunction ;;
    esac
done

if [ -z "${PROJECT_PATH}" ] || [ -z "${NUM_SAMPLES}" ] || [ -z "${INPUT_FILE}" ] || \
    [ -z "${DATA_FILE}" ] || [ -z "${OUTPUT_DIR}" ]
then
    echo "Some or all of the parameters are empty";
    helpFunction
fi


# Define auxiliary variables
DATA_ABS_PATH="${PROJECT_PATH}/${DATA_FILE}"


# Perform actions
python3 "${PROJECT_PATH}/code/sampling.py" "${NUM_SAMPLES}" "${DATA_ABS_PATH}" "${INPUT_FILE}" "${OUTPUT_DIR}"
