describe "Pod::Command::Binary" do
  describe "#initialize" do
    let(:args) { [] }
    before do
      PodPrebuild.config.reset!
      allow_any_instance_of(PodPrebuild::CachePrebuilder).to receive(:run)
      @command = Pod::Command::Binary.new(CLAide::ARGV.new(args))
    end
    after do
      PodPrebuild.config.reset!
    end

    context "option --repo is specified" do
      let(:args) { ["--repo=custom"] }
      it "updates :repo to CLI config" do
        expect(PodPrebuild.config.cli_config[:repo]).to eq("custom")
      end
    end
  end
end
