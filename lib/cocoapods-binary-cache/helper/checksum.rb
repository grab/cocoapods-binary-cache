# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

require "digest/md5"

class FolderChecksum
  def self.git_checksum(dir)
    checksum_of_files(`git ls-files #{File.realdirpath(dir).shellescape}`.split("\n"))
  rescue => e
    Pod::UI.warn "Cannot get checksum of tracked files under #{dir}: #{e}"
    checksum_of_files(Dir["#{dir}/**/*"].reject { |f| File.directory?(f) })
  end

  def self.checksum_of_files(files)
    checksums = files.sort.map { |f| Digest::MD5.hexdigest(File.read(f)) }
    Digest::MD5.hexdigest(checksums.join)
  end
end
