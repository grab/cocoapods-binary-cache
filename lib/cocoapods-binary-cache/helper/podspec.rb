module Pod
  class Specification
    def empty_source_files?
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
