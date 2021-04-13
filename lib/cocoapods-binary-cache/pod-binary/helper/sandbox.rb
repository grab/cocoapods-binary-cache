require_relative "prebuild_sandbox"

module Pod
  class Sandbox
    def prebuild_sandbox
      @prebuild_sandbox ||= Pod::PrebuildSandbox.from_standard_sandbox(self)
    end
  end
end
