#!/usr/bin/python

import argparse
import mlflow.pytorch
import os

from madminer.ml import ParameterizedRatioEstimator
from madminer.ml import ScoreEstimator


############################
##### Argument parsing #####
############################

parser = argparse.ArgumentParser()
parser.add_argument("--output_path")
parser.add_argument("--samples_path")
parser.add_argument("--alpha", type=float)
parser.add_argument("--batch_size", type=int)
parser.add_argument("--num_epochs", type=int)
parser.add_argument("--valid_split", type=float)

args = parser.parse_args()
output_dir = args.output_path
samples_path = args.samples_path
alpha = args.alpha
batch_size = args.batch_size
num_epochs = args.num_epochs
valid_split = args.valid_split


#############################
### Configuration parsing ###
#############################

path_split = os.path.split(os.path.abspath(samples_path))
sub_folder = path_split[1]

method = str(sub_folder.split("_", 3)[1])
models_dir = f'{output_dir}/models'


############################
##### Perform training #####
############################

ratio_estimator_methods = {'alice', 'alices', 'cascal', 'carl', 'rolr', 'rascal'}
score_estimator_methods = {'sally', 'sallino'}

if method in ratio_estimator_methods:
    estimator = ParameterizedRatioEstimator(n_hidden=(100, 100, 100))
    estimator.train(
        method=method,
        x=f'{samples_path}/x_{method}_train.npy',
        y=f'{samples_path}/y_{method}_train.npy',
        theta=f'{samples_path}/theta0_{method}_train.npy',
        r_xz=f'{samples_path}/r_xz_{method}_train.npy',
        t_xz=f'{samples_path}/t_xz_{method}_train.npy',
        alpha=alpha,
        n_epochs=num_epochs,
        batch_size=batch_size,
        validation_split=valid_split,
    )

elif method in score_estimator_methods:
    estimator = ScoreEstimator()
    estimator.train(
        method=method,
        x=f'{samples_path}/x_{method}_train.npy',
        t_xz=f'{samples_path}/t_xz_{method}_train.npy',
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

mlflow.log_artifacts(model_folder_path)
mlflow.pytorch.log_model(estimator.model, method)
