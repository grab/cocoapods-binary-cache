require_relative "../../pod-rome/xcodebuild_raw"
require_relative "../../pod-rome/xcodebuild_command"

module PodPrebuild
  def self.build(options)
    targets = options[:targets] || []
    return if targets.empty?

    options[:sandbox] = Pod::Sandbox.new(Pathname(options[:sandbox])) unless options[:sandbox].is_a?(Pod::Sandbox)
    options[:build_dir] = build_dir(options[:sandbox].root)

    case targets[0].platform.name
    when :ios, :tvos, :watchos
      PodPrebuild::XcodebuildCommand.new(options).run
    when :osx
      xcodebuild(
        sandbox: options[:sandbox],
        targets: targets,
        configuration: options[:configuration],
        sdk: "macosx",
        args: options[:args]
      )
    else
      raise "Unsupported platform for '#{targets[0].name}': '#{targets[0].platform.name}'"
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
