module Pod
  module UI
    class << self
      def step(message)
        section("❯❯❯ Step: #{message}".magenta) { yield if block_given? }
      end
    end
  end
end
