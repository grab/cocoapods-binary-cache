require "cocoapods-core"
require "cocoapods-binary-cache"
require "cocoapods_plugin"

require_relative "spec_helper/lockfile"
require_relative "spec_helper/tempfile"

module Pod
  UI.disable_wrap = true
  module UI
    class << self
      def puts(message = "")
      end

      def warn(message = "", actions = [])
      end

      def print(message)
      end
    end
  end
end
