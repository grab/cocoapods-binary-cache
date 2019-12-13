# bang.nguyen grabtaxi. 01 Dec 2019

require 'digest/md5'

class FolderChecksum
  def self.checksum(dir)
    files = Dir["#{dir}/**/*"].reject { |f| File.directory?(f) }
    content = files.map { |f| File.read(f) }.join
    Digest::MD5.hexdigest(content).to_s
  end
end