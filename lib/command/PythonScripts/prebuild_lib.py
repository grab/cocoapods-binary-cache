# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

import subprocess
import re
import os
import glob
from utils.fileutils import FileUtils
from utils.ziputils import ZipUtils
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


class PrebuildLib:
    def __init__(self, config):
        self.cache_repo = config.cache_repo
        self.cache_path = config.cache_path
        self.prebuild_path = config.prebuild_path
        self.delta_path = config.delta_path
        self.manifest_file = config.manifest_file
        self.devpod_cache_repo = config.devpod_cache_repo
        self.devpod_cache_path = config.devpod_cache_path
        self.devpod_prebuild_output = config.devpod_prebuild_output

        self.generated_path = config.generated_path
        self.cache_libs_path = config.cache_libs_path
        self.devpod_cache_libs_path = config.devpod_cache_libs_path

    def zip_to_cache(self, lib):
        zip_dest_path = os.path.join(self.cache_libs_path, f'{lib}.zip')
        logger.info(f'Zip {lib} to {zip_dest_path}')
        if os.path.exists(zip_dest_path):
            logger.warning(f'Lib {lib} already exists at {zip_dest_path} -> Ignore zipping!')
        else:
            os.makedirs(os.path.dirname(zip_dest_path), exist_ok=True)
            ZipUtils.zip_dir(
                os.path.join(self.generated_path, lib),
                zip_dest_path
            )

    def clean_cache(self, lib):
        lib_path = os.path.join(self.cache_libs_path, f'{lib}.zip')
        logger.info(f'Clean cache of {lib} at {lib_path}')
        FileUtils.remove_file(lib_path)

    def zip_all_libs_to_cache(self):
        os.system('rm -rf ' + self.cache_libs_path + '/*')
        FileUtils.create_dir(self.cache_libs_path)
        for dir in FileUtils.listdir_nohidden(self.generated_path):
            ZipUtils.zip_dir(self.generated_path + '/' + dir, self.cache_libs_path + '/' + dir + '.zip')
        FileUtils.copy_file_or_dir(self.prebuild_path + self.manifest_file, self.cache_path)

    def clean_and_pull(self, git_repo_dir, branch='master'):
        subprocess.run(['git', '-C', git_repo_dir, 'reset', '--hard'])
        subprocess.run(['git', '-C', git_repo_dir, 'clean', '-df'])
        subprocess.run(['git', '-C', git_repo_dir, 'checkout', branch])
        subprocess.run(['git', '-C', git_repo_dir, 'pull', '-X', 'theirs'])

    def fetch_cache(self, branch='master'):
        logger.info(f'Fetch cache to {self.cache_path} (branch: {branch})')
        with step('fetch_prebuild_libs'):
            if os.path.exists(self.cache_path):
                self.clean_and_pull(self.cache_path, branch=branch)
            else:
                subprocess.run([
                    'git',
                    'clone',
                    '--depth=1',
                    f'--branch={branch}',
                    self.cache_repo,
                    self.cache_path
                ])

    def unzip_cache(self):
        logger.info(f'Unzip cache, from {self.cache_libs_path} to {self.generated_path}')
        with step('unzip_prebuild_libs'):
            FileUtils.remove_dir(self.prebuild_path)
            FileUtils.create_dir(self.generated_path)
            FileUtils.copy_file_or_dir(os.path.join(self.cache_path, self.manifest_file), self.prebuild_path)
            # Unzip libs to pod-binary folder
            for zip_path in glob.iglob(os.path.join(self.cache_libs_path, '*.zip')):
                ZipUtils.unzip(zip_path, self.generated_path)

    def fetch_and_apply_cache(self, branch='master'):
        self.fetch_cache(branch=branch)
        self.unzip_cache()

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

    def has_libs_change(self):
        if os.path.exists(self.delta_path):
            return True
        return False

    def push_all_to_git(self, git_dir):
        with step('push to cache from dir: {}'.format(git_dir)):
            git_input_path = 'git -C ' + git_dir
            os.system('{} add .'.format(git_input_path))
            os.system('{} commit -m "Prebuild pod libs"'.format(git_input_path))
            os.system('{} push'.format(git_input_path))

    def prebuild_if_needed(self, push=True, branch='master'):
        self.fetch_and_apply_cache(branch=branch)
        self.pod_install_update_if_needed()
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

                match = re.findall(r'Deleted: \[(.*)\]', data)
                if match:
                    deleted = match[0].strip()
                    if len(deleted):
                        logger.info('Deleted frameworks: {}'.format(deleted))
                        libs = deleted.split(',')
                        for lib in libs:
                            self.clean_cache(lib.strip())
                # Copy manifest file
                FileUtils.copy_file_or_dir(self.prebuild_path + self.manifest_file, self.cache_path)
                if push:
                    self.push_all_to_git(self.cache_path)
        except Exception as e:
            raise e

    # If you use other type of server for file caching such as S3 or FTP server =>
    # use prebuild_devpod function and do the upload/download separately
    def prebuild_devpod(self, push=False, try_repo_update=False):
        self.fetch_and_apply_cache()
        self.fetch_and_apply_devpod_cache()
        self.pod_install_update_if_needed(try_repo_update)
        if push:
            ZipUtils.zip_subdirs(self.devpod_prebuild_output, self.devpod_cache_libs_path)
            self.push_all_to_git(self.devpod_cache_libs_path)

    def pod_install_update_if_needed(self, try_repo_update=False):
        if try_repo_update:
            try:
                subprocess.run(['bundle', 'exec', 'pod', 'install'], check=True)
            except subprocess.CalledProcessError:
                subprocess.run(['bundle', 'exec', 'pod', 'install', '--repo-update'], check=True)
        else:
            subprocess.run(['bundle', 'exec', 'pod', 'install'], check=True)
