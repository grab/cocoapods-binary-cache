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

    def resource_bundles
      @data["resource_bundles"] || []
    end

    def resource_bundles=(value)
      @data["resource_bundles"] = value
    end

    def build_settings
      @data["build_settings"] || {}
    end

    def build_settings=(value)
      @data["build_settings"] = value
    end

    def source_hash
      @data["source_hash"] || {}
    end

    def source_hash=(value)
      @data["source_hash"] = value
    end

    def project_root
      @data["project_root"]
    end

    def project_root=(value)
      @data["project_root"] = value
    end
  end
end
