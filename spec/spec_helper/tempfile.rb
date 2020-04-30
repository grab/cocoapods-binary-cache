require "tempfile"

def create_tempfile(basename = "", content: nil)
  Tempfile.new(basename).tap do |f|
    f << content unless content.nil?
    f.close
  end
end
