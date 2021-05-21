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


sanitize_tracking_uri() {
    tracking_uri="${1}"
    workable_dir="${2}"

    # Remove the 'file:///' prefix
    sanitized_path=${tracking_uri#'file:///'}

    # If the provided URI does not contains it: return
    if [ "${tracking_uri}" = "${sanitized_path}" ]; then
        printf "%s" "${tracking_uri}"
    else
        printf "%s" "${workable_dir}/${sanitized_path}"
    fi
}
