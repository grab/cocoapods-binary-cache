# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

from zipfile import ZipFile
import zipfile
import os
from utils.fileutils import FileUtils
from utils.logger import logger


class ZipUtils:
  @staticmethod
  def unzip(in_file, out_path=None):
    with ZipFile(in_file, 'r') as zip:
        zip.extractall(out_path)

  @staticmethod
  def zip_dir(in_dir, out_file):
    logger.info(f'Zip dir: {in_dir} -> {out_file}')
    root_len = len(os.path.dirname(in_dir))
    with zipfile.ZipFile(out_file, 'w', compression=zipfile.ZIP_DEFLATED) as zip_out:
      def _zip_dir(dir):
        contents = os.listdir(dir)
        # http://www.velocityreviews.com/forums/t318840-add-empty-directory-using-zipfile.html
        if not contents:
          archive_root = dir[root_len:].lstrip('/')
          zip_info = zipfile.ZipInfo(archive_root + '/')
          zip_out.writestr(zip_info, '')

        for item in contents:
          full_path = os.path.join(dir, item)
          if os.path.isdir(full_path) and not os.path.islink(full_path):
            _zip_dir(full_path)
          else:
            archive_root = full_path[root_len:].lstrip('/')
            if not os.path.islink(full_path):
              zip_out.write(full_path, archive_root, zipfile.ZIP_DEFLATED)
            else:
              # http://www.mail-archive.com/python-list@python.org/msg34223.html
              zip_info = zipfile.ZipInfo(archive_root)
              zip_info.external_attr = 0xA1ED0000  # Symlink magic number
              zip_out.writestr(zip_info, os.readlink(full_path))

      _zip_dir(in_dir)

  @staticmethod
  def zip_subdirs(from_dir, to_dir):
    logger.info('zip_subdirs {} -> {}'.format(from_dir, to_dir))
    FileUtils.create_dir(to_dir)
    for dir in FileUtils.listdir_nohidden(from_dir):
      logger.info('zip dir: {}'.format(dir))
      ZipUtils.zip_dir('{}/{}'.format(from_dir, dir), '{}/{}.zip'.format(to_dir, dir))
