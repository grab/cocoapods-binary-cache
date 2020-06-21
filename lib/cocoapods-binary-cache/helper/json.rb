require "json"

module PodPrebuild
  class JSONFile
    attr_reader :path
    attr_reader :data

    def initialize(path)
      @path = path
      @data = load_json
    end

    def empty?
      @data.empty?
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      @data[key] = value
    end

    def save!
      File.open(@path, "w") { |f| f.write(JSON.pretty_generate(@data)) }
    end

    private

    def load_json
      File.open(@path) { |f| JSON.parse(f.read) }
    rescue
      {}
    end
  end
end
