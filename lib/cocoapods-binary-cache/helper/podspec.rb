module Pod
  class Specification
    def empty_source_files?

      if !subspecs.empty?
        subspecs_empty = subspecs.all?(&:empty_source_files?)

        # return early if there are some files in subpec(s)
        # but process the spec itself
        if !subspecs_empty
          return false
        end
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
