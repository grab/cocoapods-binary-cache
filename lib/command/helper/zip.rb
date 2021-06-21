module PodPrebuild
  module ZipUtils
    def self.zip(path, to_dir: nil)
      basename = File.basename(path)
      out_path = to_dir.nil? ? "#{basename}.zip" : "#{to_dir}/#{basename}.zip"
      cmd = []
      cmd << "cd" << File.dirname(path)
      cmd << "&& zip -r --symlinks" << out_path << basename
      cmd << "&& cd -"
      `#{cmd.join(" ")}`
    end

    def self.unzip(path, to_dir: nil)
      cmd = []
      cmd << "unzip -nq" << path
      cmd << "-d" << to_dir unless to_dir.nil?
      `#{cmd.join(" ")}`
    end
  end
end
