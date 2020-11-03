require "fourflusher"

module PodPrebuild
  class XcodebuildCommand
    PLATFORM_OF_SDK = {
      "iphonesimulator" => "iOS",
      "appletvsimulator" => "tvOS",
      "watchsimulator" => "watchOS"
    }.freeze

    def self.xcodebuild(options)
      sdk = options[:sdk] || "iphonesimulator"
      targets = options[:targets] || [options[:target]]
      platform = PLATFORM_OF_SDK[sdk]

      cmd = ["xcodebuild"]
      cmd << "-project" << options[:sandbox].project_path.realdirpath
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

      Pod::UI.puts_indented "$ #{cmd}"
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
  end
end
