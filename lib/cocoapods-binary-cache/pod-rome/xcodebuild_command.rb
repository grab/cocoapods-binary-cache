require_relative "xcodebuild_raw"

class XcodebuildCommand
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
    build_for_sdk(simulator)
    if device_build_enabled?
      build_for_sdk(device)
      create_universal_framework
      merge_dsym unless disable_dsym?
      merge_headers
      merge_swiftmodules
    end
    collect_output(Dir[target_products_dir_of(simulator) + "/*"])
  end

  private

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
      Pod::UI.puts "Framework already exists at: #{framework_path}"
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
    create_fat_binary(
      simulator: "#{framework_path_of(simulator)}/#{module_name}",
      device: "#{framework_path_of(device)}/#{module_name}"
    )
  end

  def merge_dsym
    simulator_dsym = framework_path_of(simulator) + ".dSYM"
    device_dsym = framework_path_of(device) + ".dSYM"
    return unless File.exist?(simulator_dsym) && File.exist?(device_dsym)

    create_fat_binary(
      simulator: "#{simulator_dsym}/Contents/Resources/DWARF/#{module_name}",
      device: "#{device_dsym}/Contents/Resources/DWARF/#{module_name}"
    )
    collect_output(simulator_dsym)
  end

  def create_fat_binary(options)
    cmd = ["lipo", " -create"]
    cmd << "-output" << options[:simulator]
    cmd << options[:simulator] << options[:device]
    Pod::UI.puts `#{cmd.join(" ")}`
  end

  def merge_headers
    simulator_header_path = framework_path_of(simulator) + "/Headers/#{module_name}-Swift.h"
    device_header_path = framework_path_of(device) + "/Headers/#{module_name}-Swift.h"
    merged_header = <<~HEREDOC
      #if TARGET_OS_SIMULATOR // merged by cocoapods-binary
      #{File.read(simulator_header_path)}
      #else // merged by cocoapods-binary
      #{File.read(device_header_path)}
      #endif // merged by cocoapods-binary
    HEREDOC
    File.write(simulator_header_path, merged_header.strip)
  end

  def merge_swiftmodules
    FileUtils.cp_r(
      framework_path_of(device) + "/Modules/#{module_name}.swiftmodule/.",
      framework_path_of(simulator) + "/Modules/#{module_name}.swiftmodule"
    )
  end

  def collect_output(paths)
    paths = [paths] unless paths.is_a?(Array)
    paths.each do |path|
      FileUtils.rm_rf(File.join(output_path, File.basename(path)))
      FileUtils.mv(path, output_path)
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
