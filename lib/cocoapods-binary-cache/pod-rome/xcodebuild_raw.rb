require "fourflusher"

module PodPrebuild
  class XcodebuildCommand
    PLATFORM_OF_SDK = {
      "iphonesimulator" => "iOS",
      "appletvsimulator" => "tvOS",
      "watchsimulator" => "watchOS"
    }.freeze

    DESTINATION_OF_SDK = {
      "iphoneos" => "\"generic/platform=iOS\"",
      "iphonesimulator" => "\"generic/platform=iOS Simulator\""
    }.freeze

    def self.xcodebuild(options)
      sdk = options[:sdk] || "iphonesimulator"
      targets = options[:targets] || [options[:target]]
      platform = PLATFORM_OF_SDK[sdk]

      cmd = ["xcodebuild"]
      cmd << "-project" << options[:sandbox].project_path.realdirpath.shellescape
      targets.each { |target| cmd << "-target" << target }
      cmd << "-configuration" << options[:configuration]
      cmd << "-sdk" << sdk
      unless platform.nil?
        cmd << Fourflusher::SimControl.new.destination(:oldest, platform, options[:deployment_target])
      end
      cmd += options[:args] if options[:args]
      cmd << "build"
      cmd << "2>&1"
      cmd = cmd.join(" ")

      if !PodPrebuild.config.silent_build?
        Pod::UI.puts_indented "$ #{cmd}"
      end

      log = `#{cmd}`
      return if $?.exitstatus.zero? # rubocop:disable Style/SpecialGlobalVars

      begin
        require "xcpretty" # TODO (thuyen): Revise this dependency
        # use xcpretty to print build log
        # 64 represent command invalid. http://www.manpagez.com/man/3/sysexits/
        printer = XCPretty::Printer.new({:formatter => XCPretty::Simple, :colorize => "auto"})
        log.each_line do |line|
          printer.pretty_print(line)
        end
      rescue
        Pod::UI.puts log.red
      ensure
        raise "Fail to build targets: #{targets}"
      end
    end

    def self.xcodebuild_archive(options)
      sdk = options[:sdk] || "iphonesimulator"
      # targets = options[:targets] || [options[:target]]
      # platform = PLATFORM_OF_SDK[sdk]
      target = options[:target]

      cmd = ["xcodebuild"]
      cmd << "-project" << options[:sandbox].project_path.realdirpath.shellescape
      # targets.each { |target| cmd << "-target" << target }
      cmd << "-scheme" << target
      cmd << "-configuration" << options[:configuration]
      cmd << "-sdk" << sdk
      cmd << "-destination" << DESTINATION_OF_SDK[sdk]
      cmd << "-archivePath" << "#{options[:build_dir]}/#{options[:configuration]}-#{sdk}/#{target}"
      # unless platform.nil?
      #   cmd << Fourflusher::SimControl.new.destination(:oldest, platform, options[:deployment_target])
      # end
      cmd += options[:args] if options[:args]
      cmd << "archive"
      cmd << "2>&1"
      cmd = cmd.join(" ")

      if !PodPrebuild.config.silent_build?
        Pod::UI.puts_indented "$ #{cmd}"
      end
      
      log = `#{cmd}`
      return if $?.exitstatus.zero? # rubocop:disable Style/SpecialGlobalVars

      begin
        require "xcpretty" # TODO (thuyen): Revise this dependency
        # use xcpretty to print build log
        # 64 represent command invalid. http://www.manpagez.com/man/3/sysexits/
        printer = XCPretty::Printer.new({:formatter => XCPretty::Simple, :colorize => "auto"})
        log.each_line do |line|
          printer.pretty_print(line)
        end
      rescue
        Pod::UI.puts log.red
      ensure
        raise "Fail to archive target: #{target}"
      end
    end
  end
end
