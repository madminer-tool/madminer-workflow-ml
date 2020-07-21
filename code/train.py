#!/usr/bin/python

import mlflow
import os
import sys
import yaml
from pathlib import Path

from madminer.ml import ParameterizedRatioEstimator
from madminer.ml import ScoreEstimator


############################
##### Argument parsing #####
############################

samples_path = str(sys.argv[1])
input_file = str(sys.argv[2])
output_dir = Path(sys.argv[3])

models_dir = str(output_dir.joinpath('models'))

with open(input_file) as f:
    inputs = yaml.safe_load(f)


#############################
### Configuration parsing ###
#############################

path_split = os.path.split(os.path.abspath(samples_path))
sub_folder = path_split[1]
method = str(sub_folder.split("_", 3)[1])

alpha = inputs['alpha']
batch_size = inputs['batch_size']
num_epochs = inputs['num_epochs']
valid_split = inputs['validation_split']


############################
##### Perform training #####
############################

ratio_estimator_methods = {'alice', 'alices', 'cascal', 'carl', 'rolr', 'rascal'}
score_estimator_methods = {'sally', 'sallino'}

if method in ratio_estimator_methods:
    estimator = ParameterizedRatioEstimator(n_hidden=(100, 100, 100))
    estimator.train(
        method=method,
        alpha=alpha,
        theta=samples_path + f'/theta0_{method}_train.npy',
        x=samples_path + f'/x_{method}_train.npy',
        y=samples_path + f'/y_{method}_train.npy',
        r_xz=samples_path + f'/r_xz_{method}_train.npy',
        t_xz=samples_path + f'/t_xz_{method}_train.npy',
        n_epochs=num_epochs,
        validation_split=valid_split,
        batch_size=batch_size,
    )

elif method in score_estimator_methods:
    estimator = ScoreEstimator()
    estimator.train(
        method=method,
        x=samples_path + f'/x_{method}_train.npy',
        t_xz=samples_path + f'/t_xz_{method}_train.npy',
    )

else:
    raise ValueError('Invalid training method')


############################
#### Save trained model ####
############################

model_folder_name = method
model_folder_path = f'{models_dir}/{model_folder_name}'
os.makedirs(model_folder_path, exist_ok=True)

model_file_name = method
model_file_path = f'{model_folder_path}/{model_file_name}'
estimator.save(model_file_path)


#################################
## MLFlow tracking information ##
#################################

mlflow.set_tags({
    "context": "workflow",
    "method": method,
})

mlflow.log_params({
    "alpha": alpha,
    "batch size": batch_size,
    "num. epochs": num_epochs,
    "validation split": valid_split,
})

mlflow.log_artifacts(model_folder_path)
