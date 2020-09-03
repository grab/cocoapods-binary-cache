require_relative "xcodebuild"

module FileUtils
  def self.mvpath(src, dst, **options)
    FileUtils.rm_rf(File.join(dst, File.basename(src)))
    FileUtils.mv(src, dst, **options)
  end
end

PLATFORMS = {
  "iphonesimulator" => "iOS",
  "appletvsimulator" => "tvOS",
  "watchsimulator" => "watchOS"
}.freeze

def build_for_apple_platform(options)
  sandbox = options[:sandbox]
  build_dir = options[:build_dir]
  output_path = options[:output_path]
  target = options[:target]
  configuration = options[:configuration]
  device = options[:device]
  simulator = options[:simulator]
  bitcode_enabled = options[:bitcode_enabled]
  custom_build_options = options[:custom_build_options] || []
  custom_build_options_simulator = options[:custom_build_options_simulator] || []
  device_build_enabled = options[:device_build_enabled]

  deployment_target = target.platform.deployment_target.to_s

  target_label = target.label # name with platform if it's used in multiple platforms
  Pod::UI.puts "Prebuilding #{target_label}..."

  other_options = []
  # bitcode enabled
  other_options += ["BITCODE_GENERATION_MODE=bitcode"] if bitcode_enabled
  # make less arch to iphone simulator for faster build
  custom_build_options_simulator += ["ARCHS=x86_64", "ONLY_ACTIVE_ARCH=NO"] if simulator == "iphonesimulator"

  # paths
  target_name = target.name # equals target.label, like "AFNeworking-iOS" when AFNetworking is used in multiple platforms.
  module_name = target.product_module_name
  device_framework_path = "#{build_dir}/#{configuration}-#{device}/#{target_name}/#{module_name}.framework"
  simulator_framework_path = "#{build_dir}/#{configuration}-#{simulator}/#{target_name}/#{module_name}.framework"
  simulator_target_products_path = "#{build_dir}/#{configuration}-#{simulator}/#{target_name}"

  if !Dir.exist?(simulator_framework_path)
    is_succeed, = xcodebuild(
      sandbox: sandbox,
      target: target_label,
      configuration: configuration,
      simulator: simulator,
      deployment_target: deployment_target,
      other_options: other_options + custom_build_options_simulator
    )
    raise "Build simulator framework failed: #{target_label}" unless is_succeed
  else
    puts "Simulator framework already exist at: #{simulator_framework_path}"
  end

  unless device_build_enabled
    FileUtils.cp_r Dir["#{simulator_target_products_path}/*"], output_path
    return
  end

  if !Dir.exist?(device_framework_path)
    is_succeed, = xcodebuild(
      sandbox: sandbox,
      target: target_label,
      configuration: configuration,
      sdk: device,
      deployment_target: deployment_target,
      other_options: other_options + custom_build_options
    )
    raise "Build device framework failed: #{target_label}" unless is_succeed
  else
    puts "Device framework already exist at: #{device_framework_path}"
  end

  device_binary = device_framework_path + "/#{module_name}"
  simulator_binary = simulator_framework_path + "/#{module_name}"
  return unless File.file?(device_binary) && File.file?(simulator_binary)

  # the device_lib path is the final output file path
  # combine the binaries
  tmp_lipoed_binary_path = "#{build_dir}/#{target_name}"
  lipo_log = `lipo -create -output #{tmp_lipoed_binary_path} #{device_binary} #{simulator_binary}`
  puts lipo_log unless File.exist?(tmp_lipoed_binary_path)
  FileUtils.mvpath tmp_lipoed_binary_path, device_binary

  # collect the swiftmodule file for various archs.
  device_swiftmodule_path = device_framework_path + "/Modules/#{module_name}.swiftmodule"
  simulator_swiftmodule_path = simulator_framework_path + "/Modules/#{module_name}.swiftmodule"
  FileUtils.cp_r(simulator_swiftmodule_path + "/.", device_swiftmodule_path) if File.exist?(device_swiftmodule_path)

  # combine the generated swift headers
  # (In xcode 10.2, the generated swift headers vary for each archs)
  # https://github.com/leavez/cocoapods-binary/issues/58
  simulator_generated_swift_header_path = simulator_framework_path + "/Headers/#{module_name}-Swift.h"
  device_generated_swift_header_path = device_framework_path + "/Headers/#{module_name}-Swift.h"
  if File.exist? simulator_generated_swift_header_path
    device_header = File.read(device_generated_swift_header_path)
    simulator_header = File.read(simulator_generated_swift_header_path)
    # https://github.com/Carthage/Carthage/issues/2718#issuecomment-473870461
    combined_header_content = %Q{
#if TARGET_OS_SIMULATOR // merged by cocoapods-binary

#{simulator_header}

#else // merged by cocoapods-binary

#{device_header}

#endif // merged by cocoapods-binary
}
    File.write(device_generated_swift_header_path, combined_header_content.strip)
  end

  # handle the dSYM files
  device_dsym = "#{device_framework_path}.dSYM"
  if File.exist? device_dsym
    # lipo the simulator dsym
    simulator_dsym = "#{simulator_framework_path}.dSYM"
    if File.exist? simulator_dsym
      tmp_lipoed_binary_path = "#{output_path}/#{module_name}.draft"
      lipo_log = `lipo -create -output #{tmp_lipoed_binary_path} #{device_dsym}/Contents/Resources/DWARF/#{module_name} #{simulator_dsym}/Contents/Resources/DWARF/#{module_name}`
      puts lipo_log unless File.exist?(tmp_lipoed_binary_path)
      FileUtils.mvpath tmp_lipoed_binary_path, "#{device_framework_path}.dSYM/Contents/Resources/DWARF/#{module_name}"
    end
    FileUtils.mvpath device_dsym, output_path
  end

  # output
  output_path.mkpath unless output_path.exist?
  FileUtils.mvpath device_framework_path, output_path
end
