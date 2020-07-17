#!/usr/bin/python

import sys
import yaml

from pathlib import Path
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

num_train_samples = int(sys.argv[1])
data_file = str(sys.argv[2])
inputs_file = str(sys.argv[3])
output_dir = Path(sys.argv[4])

data_dir = str(output_dir.joinpath('data'))

with open(inputs_file) as f:
    inputs = yaml.safe_load(f)


#############################
### Configuration parsing ###
#############################

nuisance = inputs['include_nuisance_parameters']
methods = inputs['methods']
n_samples = inputs['n_samples']['train']
test_split = inputs['test_split']


#############################
#### Instantiate Sampler ####
#############################

sampler = SampleAugmenter(data_file, include_nuisance_parameters=nuisance)


#############################
## Create training samples ##
#############################

# Different methods have different arguments
train_ratio_methods = {'alice', 'alices', 'cascal', 'carl', 'rolr', 'rascal'}
train_local_methods = {'sally', 'sallino'}
train_global_methods = {'scandal'}

# Iterate through the methods
for method in methods:
    logger.info(f'Sampling from method: {method}')
    training_params = inputs[method]

    for i in range(num_train_samples):

        if method in train_ratio_methods:
            theta_0_spec = training_params['theta_0']
            theta_1_spec = training_params['theta_1']
            theta_0_vals = get_theta_values(theta_0_spec)
            theta_1_vals = get_theta_values(theta_1_spec)

            sampler.sample_train_ratio(
                theta0=theta_0_vals,
                theta1=theta_1_vals,
                n_samples=n_samples,
                folder=data_dir + f'/Samples_{method}_{i}',
                filename=method + '_train',
                test_split=test_split,
            )

        elif method in train_local_methods:
            theta_spec = training_params['theta_0']
            theta_vals = get_theta_values(theta_spec)

            sampler.sample_train_local(
                theta=theta_vals,
                n_samples=n_samples,
                folder=data_dir + f'/Samples_{method}_{i}',
                filename=method + '_train',
                test_split=test_split,
            )

        elif method in train_global_methods:
            theta_spec = training_params['theta_0']
            theta_vals = get_theta_values(theta_spec)

            sampler.sample_train_density(
                theta=theta_vals,
                n_samples=n_samples,
                folder=data_dir + f'/Samples_{method}_{i}',
                filename=method + '_train',
                test_split=test_split,
            )

        else:
            raise ValueError('Invalid sampling method')
