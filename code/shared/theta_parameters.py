#!/usr/bin/python

from madminer.sampling import benchmark
from madminer.sampling import benchmarks
from madminer.sampling import morphing_point
from madminer.sampling import random_morphing_points


############################
##### Global variables #####
############################

sampling_methods = {
    'benchmark': benchmark,
    'benchmarks': benchmarks,
    'morphing_points': morphing_point,
    'random_morphing_points': random_morphing_points,
}


#############################
##### Parsing functions #####
#############################

def parse_theta_params(theta_spec: dict):
    """
    Parses the theta parameters that the method will take later on
    :param theta_spec: theta specification on the inputs file
    :return: list
    """

    params = []

    for num, param in enumerate(theta_spec['prior']):
        params.append(
            (
                param[f'parameter_{num}']['prior_shape'],
                param[f'parameter_{num}']['prior_param_0'],
                param[f'parameter_{num}']['prior_param_1'],
            )
        )

    return params


def get_theta_values(theta_spec: dict):
    """
    Parses the theta argument specification and generates a theta value
    :param theta_spec: theta specification on the inputs file
    :return: tuple
    """

    sampling_method = theta_spec['sampling_method']

    if sampling_method == 'random_morphing_points':
        parameters = parse_theta_params(theta_spec)
        arguments = [theta_spec['sampling_number'], parameters]
    else:
        arguments = [theta_spec['sampling_arg']]

    method = sampling_methods.get(sampling_method, benchmark)
    return method(*arguments)
