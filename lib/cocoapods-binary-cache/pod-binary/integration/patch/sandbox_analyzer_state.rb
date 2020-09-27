module Pod
  class Installer
    class Analyzer
      class SandboxAnalyzer
        original_analyze = instance_method(:analyze)
        define_method(:analyze) do
          state = original_analyze.bind(self).call
          state = alter_state(state)
          state
        end

        private

        def alter_state(state)
          return state if PodPrebuild.config.tracked_prebuilt_pod_names.empty?

          prebuilt = PodPrebuild.config.tracked_prebuilt_pod_names
          Pod::UI.message "Alter sandbox state: treat prebuilt frameworks as added: #{prebuilt.to_a}"
          SpecsState.new(
            :added => (state.added + prebuilt).uniq,
            :changed => state.changed - prebuilt,
            :removed => state.deleted - prebuilt,
            :unchanged => state.unchanged - prebuilt
          )
        end
      end
    end
  end
end
