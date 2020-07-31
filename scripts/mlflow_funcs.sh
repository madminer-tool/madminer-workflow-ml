#!/usr/bin/env sh

# The script exits when a command fails or it uses undeclared variables
set -o errexit
set -o nounset


parse_mlflow_args() {
    mlflow_args="${1}"

    if [ -z "${mlflow_args}" ]; then
        printf "%s" "--"
    else
        echo "${mlflow_args}" | tr ' ' '\n' | while read -r arg; do
            printf "%s" "--param-list \"${arg}\" "
        done
    fi
}
