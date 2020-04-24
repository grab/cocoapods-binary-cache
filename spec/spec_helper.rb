require 'cocoapods-core'
require 'cocoapods_plugin'
require 'cocoapods-binary-cache'

require_relative 'helper/lockfile'

module Pod
  UI.disable_wrap = true
  module UI
    class << self
      def puts(message = '')
      end

      def warn(message = '', actions = [])
      end

      def print(message)
      end
    end
  end
end
