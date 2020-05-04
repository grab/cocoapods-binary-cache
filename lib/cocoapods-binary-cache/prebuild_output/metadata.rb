module PodPrebuild
  class Metadata < JSONFile
    def self.in_dir(dir)
      PodPrebuild::Metadata.new(dir + "metadata.json")
    end

    def resources
      @data["resources"] || []
    end

    def resources=(value)
      @data["resources"] = value
    end

    def framework_name
      @data["framework_name"]
    end

    def framework_name=(value)
      @data["framework_name"] = value
    end

    def static_framework?
      @data["static_framework"] || false
    end

    def static_framework=(value)
      @data["static_framework"] = value
    end
  end
end
