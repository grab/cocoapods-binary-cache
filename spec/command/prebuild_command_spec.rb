describe "Pod::Command::Binary::Prebuild" do
  describe "#initialize" do
    let(:args) { [] }
    before do
      PodPrebuild.config.reset!
      allow_any_instance_of(PodPrebuild::CachePrebuilder).to receive(:run)
      @command = Pod::Command::Binary::Prebuild.new(CLAide::ARGV.new(args))
    end
    after do
      PodPrebuild.config.reset!
    end

    context "option --all is specified" do
      let(:args) { ["--all"] }
      it "updates :prebuild_all_pods to CLI config" do
        expect(PodPrebuild.config.cli_config[:prebuild_all_pods]).to eq(true)
      end
    end

    context "option --config is specified" do
      let(:args) { ["--config=Test"] }
      it "updates :prebuild_config to CLI config" do
        expect(PodPrebuild.config.cli_config[:prebuild_config]).to eq("Test")
      end
    end

    context "option --targets is specified" do
      let(:args) { ["--targets=A,B,C"] }
      it "updates :prebuild_targets to CLI config" do
        expect(PodPrebuild.config.cli_config[:prebuild_targets]).to eq(["A", "B", "C"])
      end
    end

    context "option --no-fetch is specified" do
      let(:args) { ["--no-fetch"] }
      it "sets fetcher to nil" do
        expect(@command.prebuilder.fetcher).to eq(nil)
      end
    end
  end
end
