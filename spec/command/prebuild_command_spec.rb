describe "Pod::Command::Binary::Prebuild" do
  describe "#run" do
    let(:arg) { [] }
    before do
      allow_any_instance_of(PodPrebuild::CachePrebuilder).to receive(:run)
      @command = Pod::Command::Binary::Prebuild.new(CLAide::ARGV.new(arg))
      @command.run
    end
    after do
      PodPrebuild.config.dsl_config = {}
      PodPrebuild.config.cli_config = {}
    end

    context "no arguments & options are specified" do
      it "prebuilds changes only" do
        expect(PodPrebuild.config.prebuild_all_pods?).not_to eq(true)
      end
    end

    context "option --all is specified" do
      let(:arg) { ["--all"] }
      it "prebuilds all pods" do
        expect(PodPrebuild.config.prebuild_all_pods?).to eq(true)
      end
    end
  end
end
