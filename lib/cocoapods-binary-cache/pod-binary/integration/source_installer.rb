# NOTE:
# This file will only be loaded on normal pod install step
# so there's no need to check is_prebuild_stage

# Provide a special "download" process for prebuilded pods.
#
# As the frameworks is already exsited in local folder. We
# just create a symlink to the original target folder.
#
module Pod
  class Installer
    class PodSourceInstaller
      def install_for_prebuild!(standard_sanbox)
        return if !Podfile::DSL.dev_pods_enabled? && standard_sanbox.local?(name)

        # make a symlink to target folder
        # TODO (bang): Unify to 1 sandbox to optimize and avoid inconsistency
        prebuild_sandbox = Pod::PrebuildSandbox.from_standard_sandbox(standard_sanbox)
        # if spec used in multiple platforms, it may return multiple paths
        target_names = prebuild_sandbox.existed_target_names_for_pod_name(name)
        target_names.each do |name|
          real_file_folder = prebuild_sandbox.framework_folder_path_for_target_name(name)

          # If have only one platform, just place int the root folder of this pod.
          # If have multiple paths, we use a sperated folder to store different
          # platform frameworks. e.g. AFNetworking/AFNetworking-iOS/AFNetworking.framework
          target_folder = standard_sanbox.pod_dir(self.name)
          target_folder += real_file_folder.basename if target_names.count > 1
          target_folder += PodPrebuild::Config.instance.prebuilt_path
          target_folder.rmtree if target_folder.exist?
          target_folder.mkpath

          walk(real_file_folder) do |child|
            source = child
            # only make symlink to file and `.framework` folder
            if child.directory? && [".framework", ".dSYM"].include?(child.extname)
              mirror_with_symlink(source, real_file_folder, target_folder) if child.extname == ".framework"
              # Ignore dsym here to avoid cocoapods from adding install_dsym to buildphase-script
              # That can cause duplicated output files error in Xcode 11 (warning in Xcode 10)
              # We need more setup to support local debuging with prebuilt dSYM
              next false # Don't go deeper
            elsif child.file?
              mirror_with_symlink(source, real_file_folder, target_folder)
              next true
            else
              next true
            end
          end

          # symbol link copy resource for static framework
          metadata = PodPrebuild::Metadata.in_dir(real_file_folder)
          next unless metadata.static_framework?

          metadata.resources.each do |path|
            target_file_path = path
              .sub("${PODS_ROOT}", sandbox.root.to_path)
              .sub("${PODS_CONFIGURATION_BUILD_DIR}", sandbox.root.to_path)
            real_file_path = real_file_folder + metadata.framework_name + File.basename(path)
            case File.extname(path)
            when ".xib"
              # https://github.com/grab/cocoapods-binary-cache/issues/7
              # When ".xib" files are compiled in a framework, it becomes ".nib" files
              # --> We need to correct the path extension
              real_file_path = real_file_path.sub_ext(".nib")
              target_file_path = target_file_path.sub(".xib", ".nib")
            when ".bundle"
              next if metadata.resource_bundles.include?(File.basename(path))

              real_file_path = real_file_folder + File.basename(path) unless real_file_path.exist?
            end
            make_link(real_file_path, target_file_path)
          end
        end
      end

      private

      def walk(path, &action)
        return unless path.exist?

        path.children.each do |child|
          result = action.call(child, &action)
          if child.directory?
            walk(child, &action) if result
          end
        end
      end

      def make_link(source, target)
        source = Pathname.new(source)
        target = Pathname.new(target)
        target.parent.mkpath unless target.parent.exist?
        relative_source = source.relative_path_from(target.parent)
        FileUtils.ln_sf(relative_source, target)
      end

      def mirror_with_symlink(source, basefolder, target_folder)
        make_link(source, target_folder + source.relative_path_from(basefolder))
      end
    end
  end
end
