require_relative "../tool/tool"
require_relative "prebuild_sandbox"

module Pod
  # a force disable option for integral
  class Installer
    def self.force_disable_integration(value)
      @@force_disable_integration = value
    end

    old_method = instance_method(:integrate_user_project)
    define_method(:integrate_user_project) do
      if @@force_disable_integration
        return
      end
      old_method.bind(self).()
    end
  end

  # a option to disable install complete message
  class Installer
    def self.disable_install_complete_message(value)
      @@disable_install_complete_message = value
    end

    old_method = instance_method(:print_post_install_message)
    define_method(:print_post_install_message) do
      if @@disable_install_complete_message
        return
      end
      old_method.bind(self).()
    end
  end

  # option to disable write lockfiles
  class Config
    @@force_disable_write_lockfile = false
    def self.force_disable_write_lockfile(value)
      @@force_disable_write_lockfile = value
    end

    old_method = instance_method(:lockfile_path)
    define_method(:lockfile_path) do
      if @@force_disable_write_lockfile
        # As config is a singleton, sandbox_root refer to the standard sandbox.
        return PrebuildSandbox.from_standard_sanbox_path(sandbox_root).root + "Manifest.lock.tmp"
      else
        return old_method.bind(self).()
      end
    end
  end
end
