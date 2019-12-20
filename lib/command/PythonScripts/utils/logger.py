# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

import os
import logging
import colorlog


def setup_logger():
  root_logger = logging.getLogger()
  root_logger.setLevel(logging.INFO)
  format_str = '[%(asctime)s] [%(levelname)s] %(message)s'
  date_format = '%H:%M:%S'

  # Enable colorlog if you run from terminal or on CI environment
  if os.isatty(2) or os.environ.get('CI'):
    cformat = '%(log_color)s' + format_str
    colors = {
      'DEBUG': 'white',
      'INFO': 'green',
      'WARNING': 'yellow',
      'ERROR': 'red',
      'CRITICAL': 'bold_red'
    }
    formatter = colorlog.ColoredFormatter(cformat, date_format, log_colors=colors)
  else:
    formatter = logging.Formatter(format_str, date_format)
  stream_handler = logging.StreamHandler()
  stream_handler.setFormatter(formatter)
  root_logger.addHandler(stream_handler)


setup_logger()
logger = logging.getLogger('driver')
logger.setLevel(logging.DEBUG)
