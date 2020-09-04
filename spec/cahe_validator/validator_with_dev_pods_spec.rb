describe "PodPrebuild::DevPodsCacheValidator" do
  describe "#validate" do
    let(:pods) do
      {
        "A" => { :version => "0.0.5", :path => "local/A" },
        "B" => { :version => "0.0.5", :path => "local/B" },
        "C" => { :version => "0.0.5", :path => "local/C" },
        "X" => { :version => "0.0.5" }
      }
    end
    let(:generated_framework_path) { Pathname("GeneratedFrameworks") }
    let(:pod_lockfile) { gen_lockfile(pods: pods) }
    let(:prebuilt_lockfile) { gen_lockfile(pods: pods) }
    let(:source_hash) { "abc1234" }
    let(:metadata_hash) { { "source_hash" => source_hash } }

    before do
      allow_any_instance_of(PodPrebuild::Metadata).to receive(:load_json).and_return(metadata_hash)
      allow(FolderChecksum).to receive(:git_checksum).with(anything).and_return(source_hash)
      allow(FolderChecksum).to receive(:git_checksum).with("local/A").and_return("not" + source_hash)

      validation_result = PodPrebuild::DevPodsCacheValidator.new(
        pod_lockfile: pod_lockfile,
        prebuilt_lockfile: prebuilt_lockfile,
        generated_framework_path: generated_framework_path
      ).validate
      @missed = validation_result.missed
      @hit = validation_result.hit
    end

    it "detects pods with changed checksum as missed" do
      expect(@missed).to eq(Set["A"])
    end

    it "detects pods with unchanged checksum as hit" do
      expect(@hit).to eq(Set["B", "C"])
    end

    it "does not check non-dev pods" do
      expect(@missed).not_to include("X")
      expect(@hit).not_to include("X")
    end
  end
end
