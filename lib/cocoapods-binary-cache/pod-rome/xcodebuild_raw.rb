require "fourflusher"

PLATFORM_OF_SDK = {
  "iphonesimulator" => "iOS",
  "appletvsimulator" => "tvOS",
  "watchsimulator" => "watchOS"
}.freeze

def xcodebuild(options)
  sdk = options[:sdk] || "iphonesimulator"
  platform = PLATFORM_OF_SDK[sdk]

  cmd = ["xcodebuild"]
  cmd << "-project" << options[:sandbox].project_path.realdirpath
  cmd << "-scheme" << options[:target]
  cmd << "-configuration" << options[:configuration]
  cmd << "-sdk" << sdk
  cmd << Fourflusher::SimControl.new.destination(:oldest, platform, options[:deployment_target]) unless platform.nil?
  cmd += options[:args] if options[:args]
  cmd << "2>&1"
  cmd = cmd.join(" ")

  puts "xcodebuild command: #{cmd}"
  log = `#{cmd}`

  succeeded = $?.exitstatus.zero?
  unless succeeded
    begin
      raise "Unexpected error" unless log.include?("** BUILD FAILED **")

      require "xcpretty" # TODO (thuyen): Revise this dependency
      # use xcpretty to print build log
      # 64 represent command invalid. http://www.manpagez.com/man/3/sysexits/
      printer = XCPretty::Printer.new({:formatter => XCPretty::Simple, :colorize => "auto"})
      log.each_line do |line|
        printer.pretty_print(line)
      end
    rescue
      puts log.red
    end
  end
  [succeeded, log]
end
