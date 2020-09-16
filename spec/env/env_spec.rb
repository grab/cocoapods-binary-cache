describe "PodPrebuild::Env" do
  describe "stages" do
    let(:prebuild_job) { false }
    before do
      PodPrebuild::Env.reset!
      allow(PodPrebuild.config).to receive(:prebuild_job?).and_return(prebuild_job)
    end

    def expect_current_stage_as(stage)
      expect(PodPrebuild::Env.current_stage).to eq(stage)
      expect(PodPrebuild::Env.prebuild_stage?).to be(stage == :prebuild)
      expect(PodPrebuild::Env.integration_stage?).to be(stage == :integration)
    end

    context "in a prebuild job" do
      let(:prebuild_job) { true }

      it "has 2 stages: prebuild and integration" do
        expect(PodPrebuild::Env.stages).to eq([:prebuild, :integration])
      end

      it "initially lands on prebuild stage" do
        expect_current_stage_as(:prebuild)
      end

      it "transits to integration stage on next" do
        PodPrebuild::Env.next_stage!
        expect_current_stage_as(:integration)
      end
    end

    context "in a non-prebuild job" do
      it "has only 1 stage: integration" do
        expect(PodPrebuild::Env.stages).to eq([:integration])
      end

      it "initially lands on integration stage" do
        expect_current_stage_as(:integration)
      end
    end
  end
end
