# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

from argparse import ArgumentParser
from utils.logger import logger
from prebuild_lib import PrebuildLib
from prebuild_config import PrebuildConfig


def main():
  parser = ArgumentParser()
  parser.add_argument('--cmd', dest='cmd', type=str)
  parser.add_argument('--config_path', dest='config_path', type=str)
  parser.add_argument('--cache_branch', dest='cache_branch', type=str)
  parser.add_argument('--push_vendor_pods', dest='push_vendor_pods', type=lambda x: x == 'true', default=False)
  args = parser.parse_args()

  try:
    config = PrebuildConfig(args.config_path)
    prebuild_lib = PrebuildLib(config)
    if args.cmd == 'fetch':
      prebuild_lib.fetch_and_apply_cache(branch=args.cache_branch or 'master')
    elif args.cmd == 'prebuild':
      prebuild_lib.prebuild_if_needed(push=args.push_vendor_pods)
    elif args.cmd == 'fetch_devpod':
      prebuild_lib.fetch_and_apply_devpod_cache()
    elif args.cmd == 'prebuild_devpod':
      prebuild_lib.prebuild_devpod(try_repo_update=True)
    elif args.cmd == 'prebuild_devpod_and_push':
      prebuild_lib.prebuild_devpod(push=True, try_repo_update=True)
    else:
      logger.info('Wrong input, please select --cmd=fetch/prebuild/fetch_devpod')
  except Exception as e:
    raise e


if __name__ == "__main__":
  main()
