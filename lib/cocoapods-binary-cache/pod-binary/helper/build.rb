require_relative "../../pod-rome/xcodebuild_raw"
require_relative "../../pod-rome/xcodebuild_command"

module Pod
  class Prebuild
    def self.build(options)
      target = options[:target]
      return if target.nil?

      options[:sandbox] = Pod::Sandbox.new(Pathname(options[:sandbox])) unless options[:sandbox].is_a?(Pod::Sandbox)
      options[:build_dir] = build_dir(options[:sandbox].root)

      case target.platform.name
      when :ios, :tvos, :watchos
        XcodebuildCommand.new(options).run
      when :osx
        xcodebuild(
          sandbox: options[:sandbox],
          target: target.label,
          configuration: options[:configuration],
          sdk: "macosx",
          args: options[:args]
        )
      else
        raise "Unsupported platform for '#{target.name}': '#{target.platform.name}'"
      end
      raise "The build directory was not found in the expected location" unless options[:build_dir].directory?
    end

    def self.remove_build_dir(sandbox_root)
      path = build_dir(sandbox_root)
      path.rmtree if path.exist?
    end

    def self.build_dir(sandbox_root)
      sandbox_root.parent + "build"
    end
  end
end
