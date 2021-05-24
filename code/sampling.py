#!/usr/bin/python

import argparse
import mlflow
import yaml

from madminer.sampling import SampleAugmenter

from shared.steps_logging import logger, setup_logger
from shared.theta_parameters import get_theta_values


##########################
##### Set up logging #####
##########################

setup_logger("INFO")


############################
##### Argument parsing #####
############################

parser = argparse.ArgumentParser()
parser.add_argument("--data_file")
parser.add_argument("--inputs_file")
parser.add_argument("--output_path")
parser.add_argument("--n_samples_train", type=int)
parser.add_argument("--n_sampling_runs", type=int)
parser.add_argument("--nuisance", type=bool)
parser.add_argument("--test_split", type=float)

args = parser.parse_args()
data_file = args.data_file
inputs_file = args.inputs_file
output_dir = args.output_path
n_samples_train = args.n_samples_train
n_sampling_runs = args.n_sampling_runs
nuisance = args.nuisance
test_split = args.test_split


#############################
### Configuration parsing ###
#############################

data_dir = f"{output_dir}/data"

with open(inputs_file) as f:
    inputs = yaml.safe_load(f)

methods = inputs["methods"]


#############################
#### Instantiate Sampler ####
#############################

sampler = SampleAugmenter(data_file, include_nuisance_parameters=nuisance)


#############################
## Create training samples ##
#############################

# Different methods have different arguments
train_ratio_methods = {"alice", "alices", "cascal", "carl", "rolr", "rascal"}
train_local_methods = {"sally", "sallino"}
train_global_methods = {"scandal"}

# Iterate through the methods
for method in methods:
    logger.info(f"Sampling from method: {method}")
    training_params = inputs[method]

    for i in range(n_sampling_runs):

        if method in train_ratio_methods:
            theta_0_spec = training_params["theta_0"]
            theta_1_spec = training_params["theta_1"]
            theta_0_vals = get_theta_values(theta_0_spec)
            theta_1_vals = get_theta_values(theta_1_spec)

            sampler.sample_train_ratio(
                theta0=theta_0_vals,
                theta1=theta_1_vals,
                n_samples=n_samples_train,
                folder=f"{data_dir}/Samples_{method}_{i}",
                filename=f"{method}_train",
                test_split=test_split,
            )

        elif method in train_local_methods:
            theta_spec = training_params["theta_0"]
            theta_vals = get_theta_values(theta_spec)

            sampler.sample_train_local(
                theta=theta_vals,
                n_samples=n_samples_train,
                folder=f"{data_dir}/Samples_{method}_{i}",
                filename=f"{method}_train",
                test_split=test_split,
            )

        elif method in train_global_methods:
            theta_spec = training_params["theta_0"]
            theta_vals = get_theta_values(theta_spec)

            sampler.sample_train_density(
                theta=theta_vals,
                n_samples=n_samples_train,
                folder=f"{data_dir}/Samples_{method}_{i}",
                filename=f"{method}_train",
                test_split=test_split,
            )

        else:
            raise ValueError("Invalid sampling method")


#################################
## MLFlow tracking information ##
#################################

mlflow.set_tags(
    {
        "context": "workflow",
    }
)
