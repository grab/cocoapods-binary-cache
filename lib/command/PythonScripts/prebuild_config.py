# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

import os
import json


class PrebuildConfig:
  def __init__(self, config_file_path):
    try:
      with open(config_file_path) as f:
        config = json.load(f)
        self.cache_repo = config.get('prebuilt_cache_repo')
        self.cache_path = os.path.expanduser(config['cache_path'])
        self.prebuild_path = config.get('prebuild_path')
        self.generated_dir_name = config.get('generated_dir_name')
        self.delta_path = config.get('delta_path')
        self.manifest_file = config.get('manifest_file')
        self.generated_path = os.path.join(self.prebuild_path, self.generated_dir_name)
        self.cache_libs_path = os.path.join(self.cache_path, self.generated_dir_name)

        self.devpod_cache_repo = config.get('devpod_cache_repo')
        self.devpod_cache_path = config.get('devpod_cache_path')
        if self.devpod_cache_repo and self.devpod_cache_path:
          self.devpod_cache_path = os.path.expanduser(self.devpod_cache_path)
          self.devpod_prebuild_output = config.get('devpod_prebuild_output')
          self.devpod_cache_libs_path = os.path.join(self.devpod_cache_path, self.generated_dir_name)
    except Exception as e:
      raise e
