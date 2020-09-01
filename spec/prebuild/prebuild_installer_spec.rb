describe "Pod::PrebuildInstaller" do
  describe "#prebuild_frameworks!" do
    let(:tmp_dir) { create_tempdir }
    let(:prebuild_code_gen) { ->(installer) {} }

    before do
      sandbox = Pod::Sandbox.new(tmp_dir)
      @installer = Pod::PrebuildInstaller.new(
        sandbox: sandbox,
        podfile: Pod::Podfile.new,
        lockfile: Pod::Lockfile.new({}),
        cache_validation: PodPrebuild::CacheValidationResult.new
      )
      allow(@installer).to receive(:pod_targets).and_return([])
      allow(@installer).to receive(:targets_to_prebuild).and_return([])
      allow(sandbox).to receive(:exsited_framework_target_names).and_return([])
      allow(sandbox).to receive(:generate_framework_path).and_return(tmp_dir + "/Generated")
      allow(Pod::Podfile::DSL).to receive(:prebuild_code_gen).and_return(prebuild_code_gen)
    end

    after do
      FileUtils.remove_entry tmp_dir
    end

    it "runs code generation before building" do
      expect(prebuild_code_gen).to receive(:call).with(@installer)
      @installer.prebuild_frameworks!
    end
  end
end
