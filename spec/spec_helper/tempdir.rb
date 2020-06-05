require "tmpdir"

def create_tempdir(prefix_suffix = nil)
  Dir.mktmpdir(prefix_suffix)
end
