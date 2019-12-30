# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

require 'json'
require 'cocoapods'
require_relative "helper/checksum"
require_relative "pod-binary/helper/passer"

class PodCacheValidator

  # Support for development pods cache: verify checksum all dev pods
  def self.verify_devpod_checksum(sandbox, lock_file)
    devpod_path = "#{sandbox.root}/devpod/"
    target_path = sandbox.generate_framework_path
    puts "verify_devpod_checksum: #{devpod_path}"
    external_sources = lock_file.to_hash["EXTERNAL SOURCES"]
    unless File.directory?(target_path)
      FileUtils.mkdir_p(target_path)
    end
    missing_pods_dic = Hash[]
    all_local_pods = Set[]
    external_sources.each do |name, attribs|
      if attribs.class == Hash
        path = attribs[:path]
        if path
          hash = FolderChecksum.checksum(path)
          all_local_pods.add(name)
          cached_path = "#{devpod_path}#{name}_#{hash}"
          if !Dir.exists?(cached_path)
            missing_pods_dic[name] = hash
            puts "Missing devpod: #{name}_#{hash}"
          else
            FileUtils.cp_r(cached_path, "#{target_path}/#{name}")
          end
        end
      else
        puts "Error, wrong type: #{attribs}"
      end
    end
    Pod::Prebuild::CacheInfo.cache_miss_local_pods = missing_pods_dic.keys
    Pod::Prebuild::CacheInfo.cache_miss_local_pods_dic = missing_pods_dic
    Pod::Prebuild::CacheInfo.local_pods = all_local_pods
    puts "Local pod cache miss: #{Pod::Prebuild::CacheInfo.cache_miss_local_pods.count} / #{all_local_pods.count}"
  end

  # Compare pod lock version and prebuilt version, return cache miss frameworks
  def self.verify_prebuilt_vendor_pods(pod_lockfile, pod_bin_lockfile)
    outdated_libs = Set.new()
    if not pod_bin_lockfile
      puts 'No pod binary lock file.'
      return outdated_libs
    end
    if not pod_lockfile
      puts 'No pod lock file.'
      return outdated_libs
    end
    pod_lock_libs = get_libs_dic(pod_lockfile)
    pod_bin_libs = get_libs_dic(pod_bin_lockfile)

    pod_bin_libs.each do |name, prebuilt_ver|
      lock_ver = pod_lock_libs[name]
      if lock_ver
        if lock_ver != prebuilt_ver
          outdated_libs.add(name)
          puts("Warning: prebuilt lib was outdated: #{name} #{prebuilt_ver} vs #{lock_ver}".yellow)
        end
      end
    end
    outdated_libs
  end

  private

  def self.get_libs_dic(lockfile)
    pods = lockfile.to_hash["PODS"]
    libs_hash = {}
    pods.each do |item|
      if item.class == Hash
        item = item.keys[0]
      end
      arr = item.split(" ")
      libs_hash[arr[0]] = arr[1]
    end
    libs_hash
  end
end
