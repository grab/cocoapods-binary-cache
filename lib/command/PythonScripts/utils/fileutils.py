# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

import os
import shutil
import pathlib
from utils.shell import Shell


class FileUtils:
  @staticmethod
  def create_dir(path):
    if not os.path.exists(path):
      os.makedirs(path)

  @staticmethod
  def recreate_dir(path):
    if os.path.exists(path):
      shutil.rmtree(path)
    os.makedirs(path)

  @staticmethod
  def remove_file(path):
    if os.path.exists(path):
      os.remove(path)

  @staticmethod
  def remove_dir(path):
    if os.path.exists(path):
      shutil.rmtree(path)

  @staticmethod
  def copy_file_or_dir(src_path, dst_path):
    """Copy a file/dir to another file/dir.
    - Intermediate dirs of the destination path will be created.
    - If the source path does not exist, don't do anything.

    :param src_path: the source path.
    :param dst_path: the destination path.
    """
    if not os.path.exists(src_path):
      return
    elif os.path.isdir(src_path):
      shutil.copytree(src_path, dst_path)
    elif os.path.isfile(src_path):
      os.makedirs(os.path.dirname(dst_path), exist_ok=True)
      shutil.copy(src_path, dst_path)
    else:
      raise 'Only support copying file/dir'

  @staticmethod
  def concat(paths, out_path):
    """Concat contents of files.

    :param paths: the paths of the input files.
    :out_path: the path to the output file.
    """
    with open(out_path, 'wb') as f_out:
      for path in paths:
        with open(path, 'rb') as f_in:
          f_out.write(f_in.read())

  @staticmethod
  def du_sh(path):
    """Get the description about the size of a path.

    :param path: the path, could be a file or a directory.
    """
    return Shell.run('du -sh {}'.format(path))

  @staticmethod
  def get_size(path):
    """Get the size in bytes of file/directory from a path.

    :param path: the path, could be a file or a directory.
    """
    if os.path.isdir(path):
      total_size = 0
      for dirpath, _, filenames in os.walk(path):
        for f in filenames:
          fp = os.path.join(dirpath, f)
          total_size += os.path.getsize(fp)

      return total_size
    else:
      return os.path.getsize(path)

  @staticmethod
  def home_dir():
    return str(pathlib.Path.home())

  @staticmethod
  def pwd():
    return os.getcwd()

  @staticmethod
  def listdir_nohidden(path):
    if not os.path.exists(path):
      return []
    dirs = []
    for f in os.listdir(path):
      if not f.startswith('.'):
        dirs.append(f)
    return dirs
