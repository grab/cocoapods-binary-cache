require "json"

module PodPrebuild
  class JSONFile
    attr_reader :path
    attr_reader :data

    def initialize(path)
      @path = path
      @data = load_json
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      @data[key] = value
    end

    def save!
      File.open(@path, "w") { |f| f.write(@data.to_json) }
    end

    private

    def load_json
      File.open(@path) { |f| JSON.parse(f.read) }
    rescue
      {}
    end
  end
end
