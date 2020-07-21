module Pod
  class Specification
    # TODO: this detect objc lib as empty source, eg. Realm
    def empty_source_files?
      return subspecs.all?(&:empty_source_files?) unless subspecs.empty?

      check = lambda do |patterns|
        patterns = [patterns] if patterns.is_a?(String)
        patterns.reject(&:empty?).all? do |pattern|
          Xcodeproj::Constants::HEADER_FILES_EXTENSIONS.any? { |ext| pattern.end_with?(ext) }
        end
      end
      available_platforms.all? do |platform|
        check.call(consumer(platform).source_files)
      end
    end
  end
end
