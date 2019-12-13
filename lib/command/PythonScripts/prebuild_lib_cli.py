import os
import json
from argparse import ArgumentParser
from utils.logger import logger
from prebuild_lib import PrebuildLib


def main():
  parser = ArgumentParser()
  parser.add_argument('--cmd', dest='cmd', type=str)
  parser.add_argument('--config_path', dest='config_path', type=str)
  args = parser.parse_args()

  try:
    with open(args.config_path) as f:
      config = json.load(f)
      prebuild_lib = PrebuildLib(
        cache_tag=config['prebuilt_cache_tag'],
        cache_repo=config['prebuilt_cache_repo'],
        cache_path=config['cache_path'],
        prebuild_path=config['prebuild_path'],
        generated_dir_name=config['generated_dir_name'],
        delta_path=config['delta_path'],
        manifest_file=config['manifest_file'],
        devpod_cache_repo=config['devpod_cache_repo'],
        devpod_cache_path=config['devpod_cache_path'],
        devpod_prebuild_output=config['devpod_prebuild_output']
      )
      if args.cmd == 'fetch':
        prebuild_lib.fetch_and_apply_cache()
      elif args.cmd == 'prebuild':
        prebuild_lib.prebuild_if_needed()
      else:
        logger.info('Wrong input, please select --cmd=fetch/prebuild/prebuild_devpod_and_push')
  except Exception as e:
    raise e

if __name__ == "__main__":
  main()
