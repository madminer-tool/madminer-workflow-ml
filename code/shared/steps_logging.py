#!/usr/bin/python

import logging

logger = logging.getLogger()


def setup_logger(log_level: str):
    """
    Set ups a streaming logger with the specified severity level
    :param log_level: {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}
    """

    log_format = logging.Formatter(
        fmt="%(asctime)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    log_handler = logging.StreamHandler()
    log_handler.setFormatter(log_format)

    logger.addHandler(log_handler)
    logger.setLevel(log_level)
