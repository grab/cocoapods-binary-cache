# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

require 'json'
require 'cocoapods'
require_relative "helper/checksum"

class PodCacheValidator

  # Cache miss/hit checking for development pods
  # Return 2 Hashes for cache miss and cache hit libraries
  def self.verify_devpod_checksum(sandbox, lock_file)
    devpod_path = "#{sandbox.root}/devpod/"
    target_path = sandbox.generate_framework_path
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
            Pod::UI.puts "Missing devpod: #{name}_#{hash}"
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
    Pod::UI.puts "Local pod cache miss: #{missing_pods_dic.keys.count} / #{dev_pods_count}"
    return missing_pods_dic, cachehit_pods_dic
  end

  # Compare pod lock version and prebuilt version
  # Return 2 Hashes of cache miss and cache hit frameworks
  def self.verify_prebuilt_vendor_pods(pod_lockfile, pod_bin_lockfile)
    cachemiss_libs = Set.new
    cachehit_libs = Set.new
    if not pod_lockfile
      Pod::UI.puts 'No pod lock file.'
      return [cachemiss_libs, cachehit_libs]
    end
    pod_lock_libs = get_libs_dic(pod_lockfile)
    if not pod_bin_lockfile
      Pod::UI.puts 'No pod binary lock file.'
      return [get_vendor_pods(pod_lockfile), cachehit_libs]
    end
    pod_bin_libs = get_libs_dic(pod_bin_lockfile)

    dev_pods = get_dev_pods(pod_lockfile)
    pod_lock_libs.each do |name, lock_ver|
      next if dev_pods.include?(name)
      prebuilt_ver = pod_bin_libs[name]
      if lock_ver == prebuilt_ver
        cachehit_libs.add(name)
      else
        cachemiss_libs.add(name)
        Pod::UI.puts "Warning: prebuilt lib was outdated: #{name} #{prebuilt_ver} vs #{lock_ver}".yellow
      end
    end
    [cachemiss_libs, cachehit_libs]
  end

  private

  def self.get_dev_pods(lockfile)
    dev_pods = Set[]
    external_sources = lockfile.to_hash['EXTERNAL SOURCES'] || []
    external_sources.each do |name, attribs|
      if attribs.class == Hash
        path = attribs[:path]
        if path
          dev_pods.add(name)
        end
      end
    end
    dev_pods
  end

  def self.get_vendor_pods(lockfile)
    libs_dic = get_libs_dic(lockfile)
    dev_pods = get_dev_pods(lockfile)
    vendor_libs = Set.new()
    libs_dic.each do |name, _|
      next if dev_pods.include?(name)
      vendor_libs.add(name)

      # for subspec we have pattern: LibName/SubSpec so need to add LibName
      parts = name.split(File::Separator)
      if parts.any?
        vendor_libs.add(parts[0])
      end
    end
    return vendor_libs
  end

  def self.get_libs_dic(lockfile)
    pods = lockfile.to_hash["PODS"]
    libs_hash = {}
    if !pods
      Pod::UI.puts 'No pod libs'
      return libs_hash
    end
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
