module Pod
  class Installer
    # Remove the old target files if prebuild frameworks changed
    def remove_target_files_if_needed
      changes = Pod::Prebuild::Passer.prebuild_pods_changes
      updated_names = []
      if changes.nil?
        updated_names = PrebuildSandbox.from_standard_sandbox(sandbox).exsited_framework_pod_names
      else
        added = changes.added
        changed = changes.changed
        deleted = changes.deleted
        updated_names = added + changed + deleted
      end

      updated_names.each do |name|
        root_name = Specification.root_name(name)
        next if Pod::Podfile::DSL.dev_pods_enabled && sandbox.local?(root_name)

        UI.puts "Delete cached files: #{root_name}"
        target_path = sandbox.pod_dir(root_name)
        target_path.rmtree if target_path.exist?

        support_path = sandbox.target_support_files_dir(root_name)
        support_path.rmtree if support_path.exist?
      end
    end
  end
end
