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

  # Note that it will ignore empty folders
  @staticmethod
  def __zip_dir(path, ziphandler):
    dir_name = os.path.dirname(path)
    dir_name_len = len(dir_name)
    for root, _, files in os.walk(path):
        out_root = root
        if dir_name_len > 0 and out_root.startswith(dir_name):
            out_root = out_root[dir_name_len:]
        for file in files:
            name = os.path.join(root, file)
            out_name = os.path.join(out_root, file)
            ziphandler.write(name, out_name)

  @staticmethod
  def zip_dir(in_dir, out_file):
    zFile = ZipFile(out_file, 'w', zipfile.ZIP_DEFLATED)
    ZipUtils.__zip_dir(in_dir, zFile)
    zFile.close()

  @staticmethod
  def zip_subdirs(from_dir, to_dir):
    logger.info('zip_subdirs {} -> {}'.format(from_dir, to_dir))
    FileUtils.create_dir(to_dir)
    for dir in FileUtils.listdir_nohidden(from_dir):
      logger.info('zip dir: {}'.format(dir))
      ZipUtils.zip_dir('{}/{}'.format(from_dir, dir), '{}/{}.zip'.format(to_dir, dir))
