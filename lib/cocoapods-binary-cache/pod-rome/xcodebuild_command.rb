require_relative "xcodebuild_raw"

class XcodebuildCommand # rubocop:disable Metrics/ClassLength
  def initialize(options)
    @options = options
    case options[:target].platform.name
    when :ios
      @options[:device] = "iphoneos"
      @options[:simulator] = "iphonesimulator"
    when :tvos
      @options[:device] = "appletvos"
      @options[:simulator] = "appletvsimulator"
    when :watchos
      @options[:device] = "watchos"
      @options[:simulator] = "watchsimulator"
    end
    @build_args = make_up_build_args(options[:args] || {})
  end

  def run
    build_for_sdk(simulator) if build_types.include?(:simulator)
    build_for_sdk(device) if build_types.include?(:device)

    case build_types
    when [:simulator]
      collect_output(Dir[target_products_dir_of(simulator) + "/*"])
    when [:device]
      collect_output(Dir[target_products_dir_of(device) + "/*"])
    else
      # When merging contents of `simulator` & `device`, prefer contents of `device` over `simulator`
      # https://github.com/grab/cocoapods-binary-cache/issues/25
      collect_output(Dir[target_products_dir_of(device) + "/*"])
      create_universal_framework
    end
  end

  private

  def build_types
    @build_types ||= begin
      # TODO (thuyen): Add DSL options `build_for_types` to specify build types
      types = [:simulator]
      types << :device if device_build_enabled?
      types
    end
  end

  def make_up_build_args(args)
    args_ = args.clone
    args_[:default] ||= []
    args_[:simulator] ||= []
    args_[:device] ||= []
    args_[:default] += ["BITCODE_GENERATION_MODE=bitcode"] if bitcode_enabled?
    args_[:default] += ["DEBUG_INFORMATION_FORMAT=dwarf"] if disable_dsym?
    args_[:simulator] += ["ARCHS=x86_64", "ONLY_ACTIVE_ARCH=NO"] if simulator == "iphonesimulator"
    args_[:simulator] += args_[:default]
    args_[:device] += args_[:default]
    args_
  end

  def build_for_sdk(sdk)
    framework_path = framework_path_of(sdk)
    if Dir.exist?(framework_path)
      Pod::UI.puts_indented "--> Framework already exists at: #{framework_path}"
      return
    end

    succeeded, = xcodebuild(
      sandbox: sandbox,
      target: target.label,
      configuration: configuration,
      sdk: sdk,
      deployment_target: target.platform.deployment_target.to_s,
      args: sdk == simulator ? @build_args[:simulator] : @build_args[:device]
    )
    raise "Build framework failed: #{target.label}" unless succeeded
  end

  def create_universal_framework
    merge_framework_binary
    merge_framework_dsym
    merge_swift_headers
    merge_swift_modules
  end

  def merge_framework_binary
    merge_contents("/#{module_name}", &method(:create_fat_binary))
  end

  def merge_framework_dsym
    merge_contents(".dSYM/Contents/Resources/DWARF/#{module_name}", &method(:create_fat_binary))
  end

  def merge_swift_headers
    merge_contents("/Headers/#{module_name}-Swift.h") do |options|
      merged_header = <<~HEREDOC
        #if TARGET_OS_SIMULATOR // merged by cocoapods-binary
        #{File.read(options[:simulator])}
        #else // merged by cocoapods-binary
        #{File.read(options[:device])}
        #endif // merged by cocoapods-binary
      HEREDOC
      File.write(options[:output], merged_header.strip)
    end
  end

  def merge_swift_modules
    merge_contents("/Modules/#{module_name}.swiftmodule") do |options|
      # Note: swiftmodules of `device` were copied beforehand,
      # here, we only need to copy swiftmodules of `simulator`
      FileUtils.cp_r(options[:simulator] + "/.", options[:output])
    end
  end

  def merge_contents(path_suffix, &merger)
    simulator_, device_, output_ = [
      framework_path_of(simulator),
      framework_path_of(device),
      "#{output_path}/#{module_name}.framework"
    ].map { |p| p + path_suffix }
    return unless File.exist?(simulator_) && File.exist?(device_)

    merger.call(simulator: simulator_, device: device_, output: output_)
  end

  def create_fat_binary(options)
    cmd = ["lipo", " -create"]
    cmd << "-output" << options[:output]
    cmd << options[:simulator] << options[:device]
    Pod::UI.puts `#{cmd.join(" ")}`
  end

  def collect_output(paths)
    paths = [paths] unless paths.is_a?(Array)
    paths.each do |path|
      FileUtils.rm_rf(File.join(output_path, File.basename(path)))
      FileUtils.cp_r(path, output_path)
    end
  end

  def target_products_dir_of(sdk)
    "#{build_dir}/#{configuration}-#{sdk}/#{target.name}"
  end

  def framework_path_of(sdk)
    "#{target_products_dir_of(sdk)}/#{module_name}.framework"
  end

  def module_name
    target.product_module_name
  end

  def sandbox
    @options[:sandbox]
  end

  def build_dir
    @options[:build_dir]
  end

  def output_path
    @options[:output_path]
  end

  def target
    @options[:target]
  end

  def configuration
    @options[:configuration]
  end

  def bitcode_enabled?
    @options[:bitcode_enabled]
  end

  def device_build_enabled?
    @options[:device_build_enabled]
  end

  def device
    @options[:device] || "iphoneos"
  end

  def simulator
    @options[:simulator] || "iphonesimulator"
  end

  def disable_dsym?
    @options[:disable_dsym]
  end
end
