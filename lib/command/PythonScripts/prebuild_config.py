import os
import json


class PrebuildConfig:
  def __init__(self, config_file_path):
    try:
      with open(config_file_path) as f:
        config = json.load(f)
        self.cache_repo = config['prebuilt_cache_repo']
        self.cache_path = os.path.expanduser(config['cache_path'])
        self.prebuild_path = config['prebuild_path']
        self.generated_dir_name = config['generated_dir_name']
        self.delta_path = config['delta_path']
        self.manifest_file = config['manifest_file']
        self.devpod_cache_repo = config['devpod_cache_repo']
        self.devpod_cache_path = os.path.expanduser(config['devpod_cache_path'])
        self.devpod_prebuild_output = config['devpod_prebuild_output']

        # Compute other properties
        self.generated_path = self.prebuild_path + self.generated_dir_name
        self.cache_libs_path = self.cache_path + self.generated_dir_name
        self.devpod_cache_libs_path = self.devpod_cache_path + self.generated_dir_name
    except Exception as e:
      raise e
