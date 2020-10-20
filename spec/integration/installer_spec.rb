require "cocoapods-binary-cache/pod-binary/integration/patch/source_installation"

describe "Pod::Installer" do
  describe "#create_pod_installer" do
    let(:prebuilt_pod_names_cache_missed) { ["A"] }
    let(:prebuilt_pod_names_cache_hit) { ["B"] }
    let(:prebuilt_pod_names) { prebuilt_pod_names_cache_missed + prebuilt_pod_names_cache_hit }
    let(:non_prebuilt_pod_names) { ["X"] }
    let(:pod_names) { prebuilt_pod_names + non_prebuilt_pod_names }
    let(:tmp_dir) { create_tempdir }
    let(:sandbox) { Pod::Sandbox.new(tmp_dir) }

    before do
      allow(PodPrebuild.state).to receive(:cache_validation).and_return(
        PodPrebuild::CacheValidationResult.new(
          prebuilt_pod_names_cache_missed.map { |name| [name, "missing"] }.to_h,
          prebuilt_pod_names_cache_hit.to_set
        )
      )

      @installer = Pod::Installer.new(sandbox, Pod::Podfile.new, nil)
      allow(@installer).to receive(:create_prebuilt_source_installer).and_return("prebuilt")
      allow(@installer).to receive(:create_normal_source_installer).and_return("normal")
    end

    after do
      FileUtils.remove_entry tmp_dir
    end

    def expect_installed_as(type, pods)
      pods.each { |name| expect(@installer.create_pod_installer(name)).to eq(type) }
    end

    def expect_installed_as_normal(pods)
      expect_installed_as("normal", pods)
    end

    def expect_installed_as_prebuilt(pods)
      expect_installed_as("prebuilt", pods)
    end

    it "installs source of non prebuilt pods as normal" do
      expect_installed_as_normal(non_prebuilt_pod_names)
    end

    it "installs source the missed pod as normal" do
      expect_installed_as_normal(prebuilt_pod_names_cache_missed)
    end

    it "installs source of prebuilt pods with cache hit differently" do
      expect_installed_as_prebuilt(prebuilt_pod_names_cache_hit)
    end

    context "is prebuild job" do
      before do
        allow(PodPrebuild.config).to receive(:prebuild_job?).and_return(true)
      end
      it "installs source of all prebuilt pods differently" do
        expect_installed_as_prebuilt(prebuilt_pod_names)
      end

      context "targets were specified in CLI" do
        let(:targets_to_prebuild_from_cli) { ["Y"] }
        before do
          allow(PodPrebuild.config).to receive(:targets_to_prebuild_from_cli).and_return(targets_to_prebuild_from_cli)
        end
        it "installs specified targets & cache hit as prebuilt" do
          expect_installed_as_prebuilt(prebuilt_pod_names_cache_hit + targets_to_prebuild_from_cli)
        end
      end
    end
  end
end
