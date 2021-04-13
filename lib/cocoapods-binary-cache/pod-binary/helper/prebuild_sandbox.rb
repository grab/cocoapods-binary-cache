require_relative "names"

module Pod
  class PrebuildSandbox < Sandbox
    # [String] standard_sandbox_path
    def self.from_standard_sandbox_path(path)
      prebuild_sandbox_path = Pathname.new(path).realpath + ".." + PodPrebuild.config.prebuild_sandbox_path
      new(prebuild_sandbox_path)
    end

    def self.from_standard_sandbox(sandbox)
      from_standard_sandbox_path(sandbox.root)
    end

    def standard_sanbox_path
      root.parent
    end

    def generate_framework_path
      root + "GeneratedFrameworks"
    end

    # @param name [String] pass the target.name (may containing platform suffix)
    # @return [Pathname] the folder containing the framework file.
    def framework_folder_path_for_target_name(name)
      generate_framework_path + name
    end

    def exsited_framework_target_names
      existed_framework_name_pairs.map { |pair| pair[0] }.uniq
    end

    def exsited_framework_pod_names
      existed_framework_name_pairs.map { |pair| pair[1] }.uniq
    end

    def existed_target_names_for_pod_name(pod_name)
      existed_framework_name_pairs.select { |pair| pair[1] == pod_name }.map { |pair| pair[0] }
    end

    def save_pod_name_for_target(target)
      folder = framework_folder_path_for_target_name(target.name)
      return unless folder.exist?

      flag_file_path = folder + "#{target.pod_name}.pod_name"
      File.write(flag_file_path.to_s, "")
    end

    private

    def pod_name_for_target_folder(target_folder_path)
      name = Pathname.new(target_folder_path).children.find do |child|
        child.to_s.end_with? ".pod_name"
      end
      name = name.basename(".pod_name").to_s unless name.nil?
      name ||= Pathname.new(target_folder_path).basename.to_s # for compatibility with older version
      name
    end

    # Array<[target_name, pod_name]>
    def existed_framework_name_pairs
      return [] unless generate_framework_path.exist?

      generate_framework_path.children.map do |framework_path|
        if framework_path.directory? && !framework_path.children.empty?
          [framework_path.basename.to_s, pod_name_for_target_folder(framework_path)]
        end
      end.reject(&:nil?).uniq
    end
  end
end
