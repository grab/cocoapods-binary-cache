describe "Pod::PrebuildInstaller" do
  let(:tmp_dir) { create_tempdir }
  let(:sandbox) { Pod::Sandbox.new(tmp_dir) }
  let(:podfile) { Pod::Podfile.new }
  let(:lockfile) { Pod::Lockfile.new({}) }
  let(:cache_validation) { PodPrebuild::CacheValidationResult.new }

  before do
    @installer = Pod::PrebuildInstaller.new(
      sandbox: sandbox,
      podfile: podfile,
      lockfile: lockfile,
      cache_validation: cache_validation
    )
  end

  after do
    FileUtils.remove_entry tmp_dir
  end

  describe "#initialize" do
    it "sets lockfile_wrapper correctly" do
      expect(@installer.lockfile_wrapper).to be_a(PodPrebuild::Lockfile)
      expect(@installer.lockfile_wrapper.lockfile).to eq(lockfile)
    end

    context "lockfile is missing" do
      let(:lockfile) { nil }
      it "sets lockfile_wrapper as nil" do
        expect(@installer.lockfile_wrapper).to eq(nil)
      end
    end
  end

  describe "#prebuild_frameworks!" do
    let(:prebuild_code_gen) { ->(_, _) {} }
    let(:targets_to_prebuild) { [] }

    before do
      allow(@installer).to receive(:pod_targets).and_return([])
      allow(@installer).to receive(:targets_to_prebuild).and_return(targets_to_prebuild)
      allow(sandbox).to receive(:exsited_framework_target_names).and_return([])
      allow(sandbox).to receive(:generate_framework_path).and_return(tmp_dir + "/Generated")
      allow(Pod::Podfile::DSL).to receive(:prebuild_code_gen).and_return(prebuild_code_gen)
    end

    it "runs code generation before building" do
      expect(prebuild_code_gen).to receive(:call).with(@installer, targets_to_prebuild)
      @installer.prebuild_frameworks!
    end
  end
end
