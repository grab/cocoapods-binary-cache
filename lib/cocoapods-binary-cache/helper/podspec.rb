module Pod
  class Specification
    def empty_source_files?
      unless subspecs.empty?
        # return early if there are some files in subpec(s) but process the spec itself
        return false unless subspecs.all?(&:empty_source_files?)
      end

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
