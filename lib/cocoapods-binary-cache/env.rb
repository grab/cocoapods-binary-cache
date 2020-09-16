module PodPrebuild
  class Env
    @stage_idx = 0

    class << self
      def reset!
        @stage_idx = 0
        @stages = nil
      end

      def next_stage!
        @stage_idx += 1 if @stage_idx < stages.count - 1
      end

      def stages
        @stages ||= PodPrebuild.config.prebuild_job? ? [:prebuild, :integration] : [:integration]
      end

      def current_stage
        stages[@stage_idx]
      end

      def prebuild_stage?
        current_stage == :prebuild
      end

      def integration_stage?
        current_stage == :integration
      end
    end
  end
end
