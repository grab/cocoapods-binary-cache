import os
import json
from argparse import ArgumentParser
from utils.logger import logger
from prebuild_lib import PrebuildLib
from prebuild_config import PrebuildConfig

def main():
  parser = ArgumentParser()
  parser.add_argument('--cmd', dest='cmd', type=str)
  parser.add_argument('--config_path', dest='config_path', type=str)
  args = parser.parse_args()

  try:
    config = PrebuildConfig(args.config_path)
    prebuild_lib = PrebuildLib(config)  
    if args.cmd == 'fetch':
      prebuild_lib.fetch_and_apply_cache()
    elif args.cmd == 'prebuild':
      prebuild_lib.prebuild_if_needed()
    elif args.cmd == 'fetch_devpod':
      prebuild_lib.fetch_and_apply_devpod_cache()
    elif args.cmd == 'prebuild_devpod':
      prebuild_lib.prebuild_devpod()
    else:
      logger.info('Wrong input, please select --cmd=fetch/prebuild/fetch_devpod')
  except Exception as e:
    raise e

if __name__ == "__main__":
  main()
