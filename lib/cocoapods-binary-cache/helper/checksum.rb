# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

require 'digest/md5'

class FolderChecksum
  def self.checksum(dir)
    files = Dir["#{dir}/**/*"].reject { |f| File.directory?(f) }
    content = files.map { |f| File.read(f) }.join
    Digest::MD5.hexdigest(content).to_s
  end
end