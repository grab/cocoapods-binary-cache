require "cocoapods-binary-cache/pod-binary/integration/installer"

describe "Pod::Installer" do
  describe "#install_source_of_pod" do
    let(:prebuilt_pod_names) { ["A", "B"] }
    let(:non_prebuilt_pod_names) { ["X"] }
    let(:pod_names) { prebuilt_pod_names + non_prebuilt_pod_names }
    let(:pod_lockfile) do
      gen_lockfile(pods: pod_names.map { |name| [name, { :version => "0.0.5" }] }.to_h)
    end
    let(:podfile) do
      prebuilt_pod_names_ = prebuilt_pod_names
      non_prebuilt_pod_names_ = non_prebuilt_pod_names
      Pod::Podfile.new do
        source "https://cdn.cocoapods.org/"
        target "Demo" do
          prebuilt_pod_names_.each { |name| pod name, "0.0.5", :binary => true }
          non_prebuilt_pod_names_.each { |name| pod name, "0.0.5" }
        end
      end
    end
    let(:tmp_dir) { create_tempdir }
    let(:sandbox) { Pod::Sandbox.new(tmp_dir) }

    before do
      @source_installer = Object.new
      @installer = Pod::Installer.new(sandbox, podfile, pod_lockfile)
      @installer.instance_variable_set(:@installed_specs, [])
      allow(@installer).to receive(:create_pod_installer).and_return(@source_installer)
      allow(@installer).to receive(:prebuild_pod_names).and_return(prebuilt_pod_names)
      allow(@source_installer).to receive_message_chain(:specs_by_platform, :values).and_return([])
    end

    after do
      FileUtils.remove_entry tmp_dir
    end

    it "installs source of non prebuilt pods as usual" do
      non_prebuilt_pod_names.each do |name|
        expect(@source_installer).to receive(:install!)
        expect(@source_installer).not_to receive(:install_for_prebuild!)
        @installer.send(:install_source_of_pod, name)
      end
    end

    it "installs source of prebuilt pods differently" do
      prebuilt_pod_names.each do |name|
        expect(@source_installer).to receive(:install_for_prebuild!)
        expect(@source_installer).not_to receive(:install!)
        @installer.send(:install_source_of_pod, name)
      end
    end

    context "has cache miss" do
      before do
        cache_validation = PodPrebuild::CacheValidationResult.new({ "A" => "missing" }, Set.new)
        allow(PodPrebuild::StateStore).to receive(:cache_validation).and_return(cache_validation)
      end

      it "treats the missed pod as normal" do
        expect(@source_installer).to receive(:install!)
        expect(@source_installer).not_to receive(:install_for_prebuild!)
        @installer.send(:install_source_of_pod, "A")
      end

      it "treats the missed pod differently if in a prebuild_job" do
        allow(Pod::Podfile::DSL).to receive(:prebuild_job).and_return(true)

        expect(@source_installer).to receive(:install_for_prebuild!)
        expect(@source_installer).not_to receive(:install!)
        @installer.send(:install_source_of_pod, "A")
      end
    end
  end
end
