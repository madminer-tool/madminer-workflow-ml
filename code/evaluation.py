#!/usr/bin/python

import mlflow
import numpy as np
import os
import sys
import yaml
from pathlib import Path

from madminer.fisherinformation import FisherInformation
from madminer.limits import AsymptoticLimits
from madminer.ml import ParameterizedRatioEstimator
from madminer.ml import ScoreEstimator
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

inputs_file = sys.argv[1]
eval_folder = sys.argv[2]
data_file = sys.argv[3]
output_dir = Path(sys.argv[4])

model_dir = str(output_dir.joinpath('models'))
rates_dir = str(output_dir.joinpath('rates'))
results_dir = str(output_dir.joinpath('results'))
tests_dir = str(output_dir.joinpath('test'))

with open(inputs_file) as f:
    inputs = yaml.safe_load(f)


#############################
### Configuration parsing ###
#############################

asymp_info = dict(inputs['asymptotic_limits'])
fisher_info = dict(inputs['fisher_information'])
gen_method = str(os.path.split(os.path.abspath(eval_folder))[1])
include_xsec = list(inputs['include_xsec'])
histogram_var = str(inputs['histogram_vars'])
luminosity = float(inputs['luminosity'])
test_split = float(inputs['test_split'])
n_samples_test = int(inputs['n_samples']['test'])
n_samples_train = int(inputs['n_samples']['train'])


##############################
# Define data gen. functions #
##############################

def generate_test_data_ratio(method: str):
    """
    Generates test data files given a particular method (ratio)
    :param method: name of the MadMiner method to generate theta
    """

    sampler = SampleAugmenter(data_file, include_nuisance_parameters=False)
    thetas = inputs[method]

    if len(thetas) == 1:
        theta_spec = thetas['theta_0']
        theta_vals = get_theta_values(theta_spec)

        sampler.sample_test(
            theta=theta_vals,
            n_samples=n_samples_test,
            folder=f'{tests_dir}/{method}',
            filename='test',
        )

    elif len(thetas) == 2:
        theta_0_spec = thetas['theta_0']
        theta_1_spec = thetas['theta_1']
        theta_0_vals = get_theta_values(theta_0_spec)
        theta_1_vals = get_theta_values(theta_1_spec)

        sampler.sample_train_ratio(
            theta0=theta_0_vals,
            theta1=theta_1_vals,
            n_samples=n_samples_test,
            folder=f'{tests_dir}/{method}',
            filename='test',
        )


def generate_test_data_score(method: str):
    """
    Generates test data files given a particular method (score)
    :param method: name of the MadMiner method to generate theta
    """

    sampler = SampleAugmenter(data_file, include_nuisance_parameters=False)
    thetas = inputs[method]

    theta_spec = thetas['theta_0']
    theta_vals = get_theta_values(theta_spec)

    sampler.sample_train_local(
        theta=theta_vals,
        n_samples=n_samples_test,
        folder=f'{tests_dir}/{method}',
        filename='test',
    )


##############################
##### Parse theta ranges #####
##############################

def parse_theta_ranges():
    """
    Parses the minimum and maximum values for thetas
    in order to build a theta ranges.
    :return: list
    """

    ranges = []

    for asymp_theta in asymp_info['region'].keys():
        ranges.append(
            (
                asymp_info['region'][asymp_theta]['min'],
                asymp_info['region'][asymp_theta]['max'],
             )
        )

    logger.info(f'Theta ranges: {ranges}')
    return ranges


##############################
## Fisher information func. ##
##############################

def print_fisher_info():
    """ Prints Fisher information for logging purposes """

    fisher = FisherInformation(data_file, include_nuisance_parameters=False)

    fisher_obs = fisher_info['observable']
    fisher_bins = fisher_info['histogram_bins']
    fisher_range = fisher_info['histogram_range']
    fisher_theta = fisher_info['theta_true']

    info, _ = fisher.full_information(
        theta=fisher_theta,
        luminosity=luminosity,
        model_file=f'{model_dir}/{gen_method}/{gen_method}',
    )

    logger.info(f'Fisher information in rates:')
    logger.info(f'\n{info}')

    info_histo, _ = fisher.histo_information(
        theta=fisher_theta,
        luminosity=luminosity,
        observable=fisher_obs,
        bins=fisher_bins,
        histrange=fisher_range,
    )

    logger.info(f'Fisher information in 1D histogram:')
    logger.info(f'\n{info_histo}')


###############################
#### Define parameter grid ####
###############################

resolutions = asymp_info['resolutions']
theta_true = asymp_info['theta_true']
theta_ranges = parse_theta_ranges()

limits = AsymptoticLimits(data_file)
theta_grid, p_values, best_fit_index, _, _, _ = limits.expected_limits(
    mode="rate",
    theta_true=theta_true,
    grid_ranges=theta_ranges,
    grid_resolutions=resolutions,
    include_xsec=True,
    luminosity=luminosity,
)

np.save(file=f'{rates_dir}/grid.npy', arr=theta_grid)
np.save(file=f'{rates_dir}/rate.npy', arr=[p_values, best_fit_index])


################################
### Store evaluation results ###
################################

score_estimator_methods = {'sally', 'sallino'}
ratio_estimator_methods = {'alice', 'alices', 'cascal', 'carl', 'rolr', 'rascal'}

if gen_method in ratio_estimator_methods:

    # Testing data is generated
    generate_test_data_ratio(gen_method)

    # The trained model, theta grid and the test data are loaded
    estimator = ParameterizedRatioEstimator()
    estimator.load(f'{eval_folder}/{gen_method}')
    grid = np.load(f'{rates_dir}/grid.npy')
    test = np.load(f'{tests_dir}/{gen_method}/x_test.npy')

    llr, scores = estimator.evaluate_log_likelihood_ratio(
        x=test,
        theta=grid,
        test_all_combinations=True,
        evaluate_score=True,
    )

    os.makedirs(f'{results_dir}/{gen_method}', exist_ok=True)
    np.save(file=f'{results_dir}/{gen_method}/llr.npy', arr=llr)
    np.save(file=f'{results_dir}/{gen_method}/scores.npy', arr=scores)

elif gen_method in score_estimator_methods:

    if fisher_info['bool']:
        print_fisher_info()

    # Testing data is generated
    generate_test_data_score(gen_method)

    # The trained model, theta grid and the test data are loaded
    estimator = ScoreEstimator()
    estimator.load(f'{eval_folder}/{gen_method}')
    grid = np.load(f'{rates_dir}/grid.npy')
    test = np.load(f'{tests_dir}/{gen_method}/x_test.npy')

    scores = estimator.evaluate_score(
        x=test,
        theta=grid,
    )

    os.makedirs(f'{results_dir}/{gen_method}', exist_ok=True)
    np.save(file=f'{results_dir}/{gen_method}/scores.npy', arr=scores)

else:
    raise ValueError('Invalid generation method')


#################################
## MLFlow tracking information ##
#################################

mlflow.set_tags({
    "context": "workflow",
    "method": gen_method,
})

mlflow.log_params({
    "asymptotic_limits": asymp_info,
    "luminosity": luminosity,
    "test split": test_split,
})

if gen_method in ratio_estimator_methods:
    llr_means = np.mean(llr, axis=0)
    mlflow.log_metrics({
        "theta 0 LLR": llr_means[0],
        "theta 1 LLR": llr_means[1],
    })

elif gen_method in score_estimator_methods:
    score_means = np.mean(scores, axis=0)
    mlflow.log_metrics({
        "theta 0 score": score_means[0],
        "theta 1 score": score_means[1],
    })

mlflow.log_artifacts(f'{results_dir}/{gen_method}')


#################################
## Calculating expected limits ##
#################################

for flag in include_xsec:

    _, p_values, best_fit_index, _, _, _ = limits.expected_limits(
        mode="histo",
        theta_true=theta_true,
        grid_ranges=theta_ranges,
        grid_resolutions=resolutions,
        include_xsec=flag,
        luminosity=luminosity,
        hist_vars=[histogram_var],
    )

    file_dir = f'{rates_dir}'
    file_name = 'histo.npy' if flag else 'histo_kin.npy'
    file_path = f'{file_dir}/{file_name}'

    os.makedirs(file_dir, exist_ok=True)
    np.save(file=file_path, arr=[p_values, best_fit_index])


    if gen_method in ratio_estimator_methods:
        mode = 'ml'
    elif gen_method in score_estimator_methods:
        mode = 'histo'
    else:
        raise ValueError('Invalid generation method')

    _, p_values, best_fit_index, _, _, _ = limits.expected_limits(
        mode=mode,
        theta_true=theta_true,
        grid_ranges=theta_ranges,
        grid_resolutions=resolutions,
        include_xsec=flag,
        luminosity=luminosity,
        model_file=f'{eval_folder}/{gen_method}',
    )

    file_dir = f'{results_dir}/{gen_method}/{mode}'
    file_name = f'{gen_method}.npy' if flag else f'{gen_method}_kin.npy'
    file_path = f'{file_dir}/{file_name}'

    os.makedirs(file_dir, exist_ok=True)
    np.save(file=file_path, arr=[p_values, best_fit_index])
