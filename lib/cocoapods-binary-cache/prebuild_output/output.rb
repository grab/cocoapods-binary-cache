# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

module PodPrebuild
  class Output
    def initialize(prebuild_sandbox)
      @sandbox = prebuild_sandbox
    end

    def prebuild_delta_path
      @prebuild_delta_path ||= PodPrebuild::Config.instance.prebuild_delta_path
    end

    def delta_dir
      @delta_dir ||= File.dirname(prebuild_delta_path)
    end

    def clean_delta_file
      puts "Clean delta file: #{prebuild_delta_path}"
      FileUtils.rm_rf(prebuild_delta_path)
    end

    def create_dir_if_needed(dir)
      FileUtils.mkdir_p dir unless File.directory?(dir)
    end

    # Input 2 arrays of library names
    def write_delta_file(updated, deleted)
      if updated.empty? && deleted.empty?
        Pod::UI.puts "No changes in prebuild"
        return
      end

      Pod::UI.puts "Write prebuild changes to: #{prebuild_delta_path}"
      create_dir_if_needed(delta_dir)
      changes = PodPrebuild::JSONFile.new(prebuild_delta_path)
      changes["updated"] = updated
      changes["deleted"] = deleted
      changes.save!
    end

    def process_prebuilt_dev_pods
      devpod_output_path = "#{delta_dir}/devpod_prebuild_output/"
      create_dir_if_needed(devpod_output_path)
      Pod::UI.puts "Copy prebuilt devpod frameworks to output dir: #{devpod_output_path}"

      # Inject project path (where the framework is built) to support generating code coverage later
      project_root = PathUtils.remove_last_path_component(@sandbox.standard_sanbox_path.to_s)
      template_file_path = devpod_output_path + "prebuilt_map"
      File.open(template_file_path, "w") do |file|
        file.write(project_root)
      end

      # FIXME (thuyen): Revise usage of cache_miss_dev_pods_dic
      # The behavior of processing outputs of dev pods and non-dev pods should be very SIMILAR
      cache_miss_dev_pods_dic = {}

      cache_miss_dev_pods_dic.each do |name, hash|
        Pod::UI.puts "Output dev pod lib: #{name} hash: #{hash}"
        built_lib_path = @sandbox.framework_folder_path_for_target_name(name)
        next unless File.directory?(built_lib_path)

        FileUtils.cp(template_file_path, "#{built_lib_path}/#{name}.framework")
        target_dir = "#{devpod_output_path}#{name}_#{hash}"
        Pod::UI.puts "From: #{built_lib_path} -> #{target_dir}"
        FileUtils.cp_r(built_lib_path, target_dir)
      end
    end
  end
end
