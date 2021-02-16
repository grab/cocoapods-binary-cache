# A fix in embeded frameworks script.
#
# The framework file in pod target folder is a symblink. The EmbedFrameworksScript use `readlink`
# to read the read path. As the symlink is a relative symlink, readlink cannot handle it well. So
# we override the `readlink` to a fixed version.
#
module Pod
  module Generator
    class EmbedFrameworksScript
      old_method = instance_method(:script)
      define_method(:script) do
        script = old_method.bind(self).call
        patch = <<-SH.strip_heredoc
          #!/bin/sh
          # ---- this is added by cocoapods-binary ---
          # Readlink cannot handle relative symlink well, so we override it to a new one
          # If the path isn't an absolute path, we add a realtive prefix.
          old_read_link=`which readlink`
          readlink () {
            path=`$old_read_link "$1"`;
            if [ $(echo "$path" | cut -c 1-1) = '/' ]; then
              echo $path;
            else
              echo "`dirname $1`/$path";
            fi
          }
          # ---
        SH

        # patch the rsync for copy dSYM symlink
        script = script.gsub "rsync --delete", "rsync --copy-links --delete"
        patch + script
      end
    end
  end
end
