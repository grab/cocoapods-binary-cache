describe "PodPrebuild::PodfileChangesCacheValidator" do
  describe "#validate" do
    let(:pods) do
      {
        "A" => { :version => "0.0.5" },
        "B" => { :version => "0.0.5" },
        "C" => { :version => "0.0.5" }
      }
    end
    let(:prebuilt_lockfile) { gen_lockfile(pods: pods) }
    let(:dev_pods_enabled) { true }
    let(:podfile) do
      Pod::Podfile.new do
        source "https://cdn.cocoapods.org/"
        pod "A", "0.0.6"  # Updated
        pod "B", "0.0.5"
        pod "C", "0.0.5"
        pod "D", "0.0.5"  # Added
        pod "E", :path => "Local/" # Added, but local
      end
    end

    before do
      allow(Pod::Podfile::DSL).to receive(:dev_pods_enabled).and_return(dev_pods_enabled)
      validation_result = PodPrebuild::PodfileChangesCacheValidator.new(
        podfile: podfile,
        prebuilt_lockfile: prebuilt_lockfile
      ).validate
      @missed = validation_result.missed
      @hit = validation_result.hit
    end

    it "returns changes as missed" do
      expect(@missed).to eq(Set["A", "D", "E"])
      expect(@hit).to eq(Set["B", "C"])
    end
  end
end
