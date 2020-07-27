describe "Lockfile" do
  describe "data extraction" do
    let(:dev_pods) do
      {
        "A_dev" => { :path => "local" },
        "B_dev" => { :path => "local" }
      }
    end
    let(:external_remote_pods) do
      {
        "C_remote" => { :git => "remote_url", :tag => "0.0.1" },
        "D_remote" => { :git => "remote_url", :commit => "abc1234" }
      }
    end
    let(:non_dev_pods) { external_remote_pods.merge("E" => { :version => "0.0.1" }) }
    let(:external_pods) { dev_pods.merge(external_remote_pods) }
    let(:pods) { dev_pods.merge(non_dev_pods) }
    let(:internal_lockfile) { gen_lockfile(pods: pods) }
    before do
      @lockfile = PodPrebuild::Lockfile.new(internal_lockfile)
    end

    it "extracts data correctly" do
      expect(@lockfile.pods.keys).to eq(pods.keys)
      expect(@lockfile.external_sources).to eq(external_pods)
      expect(@lockfile.dev_pods.keys).to eq(dev_pods.keys)
      expect(@lockfile.send(:dev_pod_hashes_map).keys).to eq(dev_pods.keys)
      expect(@lockfile.non_dev_pods.keys).to eq(non_dev_pods.keys)
    end

    context "has subspec pods" do
      let(:external_remote_pods) do
        {
          "C_remote" => { :git => "remote_url", :tag => "0.0.1" },
          "S/A" => { :git => "remote_url", :tag => "0.0.1" },
          "S/B" => { :git => "remote_url", :tag => "0.0.1" },
          "T/C" => { :git => "remote_url", :tag => "0.0.1" },
          "DevA" => { :path => "local" },
          "DevA/Sub" => { :path => "local" }
        }
      end
      it "extracts subspec pods correctly" do
        subspec_pods = {
          "S" => ["S/A", "S/B"],
          "T" => ["T/C"]
        }
        expect(@lockfile.subspec_vendor_pods).to eq(subspec_pods)
      end
    end
  end
end
