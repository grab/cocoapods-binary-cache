require_relative "xcodebuild_raw"

module PodPrebuild
  class XcodebuildCommand # rubocop:disable Metrics/ClassLength
    def initialize(options)
      @options = options
      case options[:targets][0].platform.name
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

      targets.each do |target|
        case build_types
        when [:simulator]
          collect_output(target, Dir[target_products_dir_of(target, simulator) + "/*"])
        when [:device]
          collect_output(target, Dir[target_products_dir_of(target, device) + "/*"])
        else
          # When merging contents of `simulator` & `device`, prefer contents of `device` over `simulator`
          # https://github.com/grab/cocoapods-binary-cache/issues/25
          collect_output(target, Dir[target_products_dir_of(target, device) + "/*"])
          create_universal_framework(target)
        end
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
      args_[:device] += ["ONLY_ACTIVE_ARCH=NO"]
      args_[:device] += args_[:default]
      args_
    end

    def build_for_sdk(sdk)
      PodPrebuild::XcodebuildCommand.xcodebuild(
        sandbox: sandbox,
        scheme: scheme,
        targets: targets.map(&:label),
        configuration: configuration,
        sdk: sdk,
        deployment_target: targets.map { |t| t.platform.deployment_target }.max.to_s,
        args: sdk == simulator ? @build_args[:simulator] : @build_args[:device]
      )
    end

    def create_universal_framework(target)
      merge_framework_binary(target)
      merge_framework_dsym(target)
      merge_swift_headers(target)
      merge_swift_modules(target)
    end

    def merge_framework_binary(target)
      merge_contents(target, "/#{target.product_module_name}", &method(:create_fat_binary))
    end

    def merge_framework_dsym(target)
      merge_contents(
        target,
        ".dSYM/Contents/Resources/DWARF/#{target.product_module_name}",
        &method(:create_fat_binary)
      )
    end

    def merge_swift_headers(target)
      merge_contents(target, "/Headers/#{target.product_module_name}-Swift.h") do |options|
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

    def merge_swift_modules(target)
      merge_contents(target, "/Modules/#{target.product_module_name}.swiftmodule") do |options|
        # Note: swiftmodules of `device` were copied beforehand,
        # here, we only need to copy swiftmodules of `simulator`
        FileUtils.cp_r(options[:simulator] + "/.", options[:output])
      end
    end

    def merge_contents(target, path_suffix, &merger)
      simulator_, device_, output_ = [
        framework_path_of(target, simulator),
        framework_path_of(target, device),
        "#{output_path(target)}/#{target.product_module_name}.framework"
      ].map { |p| p + path_suffix }
      return unless File.exist?(simulator_) && File.exist?(device_)

      merger.call(simulator: simulator_, device: device_, output: output_)
    end

    def create_fat_binary(options)
      cmd = ["lipo", " -create"]
      cmd << "-output" << options[:output]
      cmd << options[:simulator] << options[:device]
      `#{cmd.join(" ")}`
    end

    def collect_output(target, paths)
      FileUtils.mkdir_p(output_path(target))
      paths = [paths] unless paths.is_a?(Array)
      paths.each do |path|
        FileUtils.rm_rf(File.join(output_path(target), File.basename(path)))
        FileUtils.cp_r(path, output_path(target))
      end
    end

    def target_products_dir_of(target, sdk)
      "#{build_dir}/#{configuration}-#{sdk}/#{target.name}"
    end

    def framework_path_of(target, sdk)
      "#{target_products_dir_of(target, sdk)}/#{target.product_module_name}.framework"
    end

    def sandbox
      @options[:sandbox]
    end

    def build_dir
      @options[:build_dir]
    end

    def output_path(target)
      "#{@options[:output_path]}/#{target.label}"
    end

    def scheme
      @options[:scheme]
    end

    def targets
      @options[:targets]
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
end
