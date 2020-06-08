# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

require 'json'
require 'cocoapods'
require_relative "helper/checksum"

class PodCacheValidator

  # Cache miss/hit checking for development pods
  # Return 2 Hashes for cache miss and cache hit libraries
  def self.verify_devpod_checksum(sandbox_root, generated_framework_path, lock_file)
    devpod_path = "#{sandbox_root}/devpod/"
    target_path = generated_framework_path
    Pod::UI.puts "verify_devpod_checksum: #{devpod_path}"
    external_sources = lock_file.to_hash["EXTERNAL SOURCES"]
    unless File.directory?(target_path)
      FileUtils.mkdir_p(target_path)
    end
    missing_pods_dic = Hash[]
    dev_pods_count = 0
    cachehit_pods_dic = Hash[]
    if !external_sources
      Pod::UI.puts 'No development pods!'
      return missing_pods_dic, cachehit_pods
    end
    external_sources.each do |name, attribs|
      if attribs.class == Hash
        path = attribs[:path]
        if path
          hash = FolderChecksum.checksum(path)
          dev_pods_count += 1
          cached_path = "#{devpod_path}#{name}_#{hash}"
          if !Dir.exists?(cached_path)
            missing_pods_dic[name] = hash
          else
            cachehit_pods_dic[name] = hash
            target_dir = "#{target_path}/#{name}"
            FileUtils.rm_r(target_dir, :force => true)
            FileUtils.cp_r(cached_path, target_dir)
          end
        end
      else
        Pod::UI.puts "Error, wrong type: #{attribs}"
      end
    end
    return missing_pods_dic, cachehit_pods_dic
  end
end
