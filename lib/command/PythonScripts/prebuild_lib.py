import sys
import subprocess
import re
import os
import glob
from utils.fileutils import FileUtils
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

    def __init__(self, **kwargs):
        self.cache_tag = kwargs['cache_tag']
        self.cache_repo = kwargs['cache_repo']
        self.cache_path = kwargs['cache_path']
        self.prebuild_path = kwargs['prebuild_path']
        self.generated_dir_name = kwargs['generated_dir_name']
        self.delta_path = kwargs['delta_path']
        self.manifest_file = kwargs['manifest_file']
        self.generated_path = self.prebuild_path + self.generated_dir_name + '/'
        self.cache_libs_path = self.cache_path + self.generated_dir_name + '/'

    @print_func_name
    def zip_to_cache(self, libName):
        if os.path.exists(self.cache_libs_path + libName + '.zip'):
            logger.info('Warning: lib {} already exist'.format(libName))
        else:
            input_dir = '{}/{}'.format(self.generated_path, libName)
            output_file = '{}/{}.zip'.format(self.cache_libs_path, libName)
            print(input_dir)
            print(output_file)
            ZipUtils.zip_dir(
                input_dir,
                output_file
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

    @print_func_name
    def fetch_cache(self):
        with step('fetch_prebuild_libs'):
            if not os.path.exists(self.cache_path):
                subprocess.run(['git', 'clone', '--depth=2', self.cache_repo, self.cache_path])
            git_input_path = ' -C ' + self.cache_path + ' '
            # Delete all local tag if any
            os.system('git' + git_input_path + 'tag -l | xargs git' + git_input_path + 'tag -d')
            os.system('git {} fetch --tags'.format(git_input_path))
            subprocess.run(['git', '-C', self.cache_path, 'checkout', self.cache_tag])

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
    def has_libs_change(self):
        if os.path.exists(self.delta_path):
            return True
        return False

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
                matches = re.findall(r'Updated: \[(.*)\]', data)
                if matches:
                    updated = matches[0].strip()
                    logger.info("Updated frameworks: {}".format(updated))
                    if len(updated):
                        libs = updated.split(',')
                        for lib in libs:
                            libName = lib.strip()
                            self.clean_cache(libName)
                            self.zip_to_cache(libName)

                deletedMatches = re.findall(r'Deleted: \[(.*)\]', data)
                logger.info(deletedMatches)
                if deletedMatches:
                    deleted = deletedMatches[0].strip()
                    logger.info('Deleted frameworks: {}'.format(deleted))
                    if len(deleted):
                        libs = deleted.split(',')
                        for lib in libs:
                            self.clean_cache(lib.strip())
                # Copy manifest file
                FileUtils.copy_file_or_dir(self.prebuild_path + self.manifest_file, self.cache_path)

                # Push to cache repo
                git_input_path = 'git -C ' + self.cache_path
                os.system('{} add .'.format(git_input_path))
                os.system('{} commit -m "Prebuild libs"'.format(git_input_path))
                os.system('{} push'.format(git_input_path))

        except Exception as e:
            raise e
