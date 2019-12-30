# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

import subprocess
import re
import os
import glob
from utils.fileutils import FileUtils
from utils.ziputils import ZipUtils
from functools import wraps
from utils.logger import logger
from utils.step import step

# PREBUILD POD LIBS FLOW
# Normal build, it automatically:
# 1. Fetch binary cache from separated repo and unzip it to pod-binary folder.
# 2. pod-binary hook pod install and will use those cached libraries.
# When upgrade a library, need to do:
# 1. Need to run this script to prebuild/delete the libs which have change.
# 2. Commit binary changes to cache repo, set tag for it.
# 3. Update tag in this file. Then submit a new MR.


def print_func_name(func):
    @wraps(func)
    def echo_func(*func_args, **func_kwargs):
        logger.info('🚀 Start func: {}'.format(func.__name__))
        return func(*func_args, **func_kwargs)
    return echo_func


class PrebuildLib:
    def __init__(self, config):
        self.cache_repo = config.cache_repo
        self.cache_path = config.cache_path
        self.prebuild_path = config.prebuild_path
        self.generated_dir_name = config.generated_dir_name
        self.delta_path = config.delta_path
        self.manifest_file = config.manifest_file
        self.devpod_cache_repo = config.devpod_cache_repo
        self.devpod_cache_path = config.devpod_cache_path
        self.devpod_prebuild_output = config.devpod_prebuild_output

        self.generated_path = config.generated_path
        self.cache_libs_path = config.cache_libs_path
        self.devpod_cache_libs_path = config.devpod_cache_libs_path

    @print_func_name
    def zip_to_cache(self, libName):
        if os.path.exists(self.cache_libs_path + libName + '.zip'):
            logger.info('Warning: lib {} already exist'.format(libName))
        else:
            ZipUtils.zip_dir(
                '{}/{}'.format(self.generated_path, libName),
                '{}/{}.zip'.format(self.cache_libs_path, libName)
            )

    @print_func_name
    def clean_cache(self, libName):
        FileUtils.remove_file(self.cache_libs_path + libName + ".zip")

    @print_func_name
    def zip_all_libs_to_cache(self):
        os.system('rm -rf ' + self.cache_libs_path + '/*')
        FileUtils.create_dir(self.cache_libs_path)
        for dir in FileUtils.listdir_nohidden(self.generated_path):
            ZipUtils.zip_dir(self.generated_path + '/' + dir, self.cache_libs_path + '/' + dir + '.zip')
        FileUtils.copy_file_or_dir(self.prebuild_path + self.manifest_file, self.cache_path)

    def clean_and_pull(self, git_repo_dir):
        subprocess.run(['git', '-C', git_repo_dir, 'reset', '--hard'])
        subprocess.run(['git', '-C', git_repo_dir, 'clean', '-df'])
        subprocess.run(['git', '-C', git_repo_dir, 'checkout', 'master'])
        subprocess.run(['git', '-C', git_repo_dir, 'pull', '-X', 'theirs'])

    @print_func_name
    def fetch_cache(self):
        with step('fetch_prebuild_libs'):
            if not os.path.exists(self.cache_path):
                subprocess.run(['git', 'clone', '--depth=1', self.cache_repo, self.cache_path])
            else:
                self.clean_and_pull(self.cache_path)

    @print_func_name
    def unzip_cache(self):
        with step('unzip_prebuild_libs'):
            FileUtils.remove_dir(self.prebuild_path)
            FileUtils.create_dir(self.generated_path)
            FileUtils.copy_file_or_dir(self.cache_path + self.manifest_file, self.prebuild_path)
            # Unzip libs to pod-binary folder
            for zipPath in glob.iglob(self.cache_libs_path + '/*.zip'):
                ZipUtils.unzip(zipPath, self.generated_path)

    @print_func_name
    def fetch_and_apply_cache(self):
        self.fetch_cache()
        self.unzip_cache()

    @print_func_name
    def fetch_and_apply_devpod_cache(self):
        with step('fetch_and_apply_devpod_cache'):
            logger.info('Fetching devpod cache to {}'.format(self.devpod_cache_path))
            if not os.path.exists(self.devpod_cache_path):
                subprocess.run(['git', 'clone', '--depth=1', self.devpod_cache_repo, self.devpod_cache_path])
            else:
                self.clean_and_pull(self.devpod_cache_path)

            # Unzip devpod libs
            devpod_temp_dir = self.prebuild_path + 'devpod/'
            logger.info('Unzip from: {} to: {}'.format(self.devpod_cache_libs_path, devpod_temp_dir))
            for zip_path in glob.iglob(self.devpod_cache_libs_path + '/*.zip'):
                ZipUtils.unzip(zip_path, devpod_temp_dir)

    @print_func_name
    def has_libs_change(self):
        if os.path.exists(self.delta_path):
            return True
        return False

    def push_all_to_git(self, git_dir):
        git_input_path = 'git -C ' + self.cache_path
        os.system('{} add .'.format(git_input_path))
        os.system('{} commit -m "Prebuild pod libs"'.format(git_input_path))
        os.system('{} push'.format(git_input_path))

    @print_func_name
    def prebuild_if_needed(self):
        self.fetch_and_apply_cache()
        subprocess.run(['bundle', 'exec', 'pod', 'install'], check=True)
        # Sync with cache directory

        if not os.path.isfile(self.delta_path):
            logger.info('No change in prebuilt frameworks')
            return
        try:
            with open(self.delta_path) as f:
                FileUtils.create_dir(self.cache_path)
                data = f.read()
                data = re.sub('"', '', data)
                updatedMatches = re.findall(r'Updated: \[(.*)\]', data)
                if updatedMatches:
                    updated = updatedMatches[0].strip()
                    logger.info("Updated frameworks: {}".format(updated))
                    if len(updated):
                        libs = updated.split(',')
                        for lib in libs:
                            libName = lib.strip()
                            self.clean_cache(libName)
                            self.zip_to_cache(libName)

                deletedMatches = re.findall(r'Deleted: \[(.*)\]', data)
                if deletedMatches:
                    deleted = deletedMatches[0].strip()
                    logger.info('Deleted frameworks: {}'.format(deleted))
                    if len(deleted):
                        libs = deleted.split(',')
                        for lib in libs:
                            self.clean_cache(lib.strip())
                # Copy manifest file
                FileUtils.copy_file_or_dir(self.prebuild_path + self.manifest_file, self.cache_path)
                self.push_all_to_git(self.cache_path)
        except Exception as e:
            raise e

    @print_func_name
    def prebuild_devpod(self):
        self.fetch_and_apply_cache()
        self.fetch_and_apply_devpod_cache()
        subprocess.run(['bundle', 'exec', 'fastlane', 'run', 'cocoapods', 'try_repo_update_on_error:true'], check=True)
