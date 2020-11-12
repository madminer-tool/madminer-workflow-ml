#!/usr/bin/python

from madminer.ml import ParameterizedRatioEstimator
from madminer.ml import QuadraticMorphingAwareRatioEstimator
from shared.steps_logging import logger


############################
##### Global variables #####
############################

ratio_estimators = {
    "parameterized": ParameterizedRatioEstimator,
    "quadratic": QuadraticMorphingAwareRatioEstimator,
}


#############################
#### Selection functions ####
#############################

def get_ratio_estimator(estimator_name: str):
    """
    Returns the desired ratio estimator class defined by its string name
    :param estimator_name: name to identify the desired estimator
    :return: ConditionalEstimator
    """

    try:
        estimator_cls = ratio_estimators[estimator_name]
    except KeyError:
        logger.info(f"Invalid name: {estimator_name}. Defaulting to Parameterized")
        estimator_cls = ParameterizedRatioEstimator

    return estimator_cls
