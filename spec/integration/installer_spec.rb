require "cocoapods-binary-cache/pod-binary/integration/patch/source_installation"

describe "Pod::Installer" do
  describe "#install_source_of_pod" do
    let(:prebuilt_pod_names_cache_missed) { ["A"] }
    let(:prebuilt_pod_names_cache_hit) { ["B"] }
    let(:prebuilt_pod_names) { prebuilt_pod_names_cache_missed + prebuilt_pod_names_cache_hit }
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
      cache_validation = PodPrebuild::CacheValidationResult.new(
        prebuilt_pod_names_cache_missed.map { |name| [name, "missing"] }.to_h,
        prebuilt_pod_names_cache_hit.to_set
      )
      allow(PodPrebuild::StateStore).to receive(:cache_validation).and_return(cache_validation)
      @source_installer = Object.new
      @installer = Pod::Installer.new(sandbox, podfile, pod_lockfile)
      @installer.instance_variable_set(:@installed_specs, [])
      allow(@installer).to receive(:create_pod_installer).and_return(@source_installer)
      allow(@source_installer).to receive_message_chain(:specs_by_platform, :values).and_return([])
    end

    after do
      FileUtils.remove_entry tmp_dir
    end

    it "installs source of non prebuilt pods as normal" do
      non_prebuilt_pod_names.each do |name|
        expect(@source_installer).to receive(:install!)
        expect(@source_installer).not_to receive(:install_for_prebuild!)
        @installer.send(:install_source_of_pod, name)
      end
    end

    it "installs source the missed pod as normal" do
      prebuilt_pod_names_cache_missed.each do |name|
        expect(@source_installer).to receive(:install!)
        expect(@source_installer).not_to receive(:install_for_prebuild!)
        @installer.send(:install_source_of_pod, name)
      end
    end

    it "installs source of prebuilt pods with cache hit differently" do
      prebuilt_pod_names_cache_hit.each do |name|
        expect(@source_installer).to receive(:install_for_prebuild!)
        expect(@source_installer).not_to receive(:install!)
        @installer.send(:install_source_of_pod, name)
      end
    end

    context "is prebuild job" do
      it "install source of all prebuilt pods differently" do
        allow(Pod::Podfile::DSL).to receive(:prebuild_job?).and_return(true)

        prebuilt_pod_names.each do |name|
          expect(@source_installer).to receive(:install_for_prebuild!)
          expect(@source_installer).not_to receive(:install!)
          @installer.send(:install_source_of_pod, name)
        end
      end
    end
  end
end
