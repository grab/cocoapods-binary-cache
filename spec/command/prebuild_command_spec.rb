describe "Pod::Command::Binary::Prebuild" do
  describe "#run" do
    let(:arg) { [] }
    before do
      allow(PodPrebuild::Config).to receive(:instance).and_return(nil)
      allow_any_instance_of(PodPrebuild::CachePrebuilder).to receive(:run)
      @command = Pod::Command::Binary::Prebuild.new(CLAide::ARGV.new(arg))
      @command.run
    end
    after do
      Pod::Podfile::DSL.binary_cache_config = {}
      Pod::Podfile::DSL.binary_cache_cli_config = {}
    end

    context "no arguments & options are specified" do
      it "prebuilds changes only" do
        expect(Pod::Podfile::DSL.prebuild_all_pods?).not_to eq(true)
      end
    end

    context "option --all is specified" do
      let(:arg) { ["--all"] }
      it "prebuilds all pods" do
        expect(Pod::Podfile::DSL.prebuild_all_pods?).to eq(true)
      end
    end
  end
end
