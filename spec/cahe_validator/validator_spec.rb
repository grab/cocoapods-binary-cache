describe "PodPrebuild::CacheValidator" do
  describe "verify prebuilt vendor pods" do
    let(:pods) do
      {
        "A" => { :version => "0.0.5" },
        "B" => { :version => "0.0.5" },
        "C" => { :version => "0.0.5" }
      }
    end
    let(:podfile) { nil }
    let(:pod_lockfile) { gen_lockfile(pods: pods) }
    let(:prebuilt_lockfile) { gen_lockfile(pods: pods) }
    let(:validate_prebuilt_settings) { nil }
    let(:generated_framework_path) { nil }
    let(:prebuilt_settings) do
      {
        "build_settings" => {
          "SWIFT_VERSION" => "5.0",
          "MACH_O_TYPE" => "staticlib"
        }
      }
    end
    let(:ignored_pods) { nil }
    before do
      allow_any_instance_of(PodPrebuild::Metadata).to receive(:load_json).and_return(prebuilt_settings)

      validation_result = PodPrebuild::CacheValidator.new(
        podfile: podfile,
        pod_lockfile: pod_lockfile,
        prebuilt_lockfile: prebuilt_lockfile,
        validate_prebuilt_settings: validate_prebuilt_settings,
        generated_framework_path: generated_framework_path,
        ignored_pods: ignored_pods
      ).validate
      @missed = validation_result.missed
      @hit = validation_result.hit
    end

    context "all cache hits" do
      it "returns non missed, all hit" do
        expect(@missed).to be_empty
        expect(@hit).to eq(pods.keys.to_set)
      end
    end

    context "some cache miss due to outdated" do
      let(:pod_lockfile) { gen_lockfile(pods: pods.merge("A" => { :version => "0.0.1" })) }
      it "returns some missed, some hit" do
        expect(@missed).to eq(["A"].to_set)
        expect(@hit).to eq(pods.keys.to_set - ["A"])
      end
    end

    context "some cache miss due to not present" do
      let(:pod_lockfile) { gen_lockfile(pods: pods.merge("D" => { :version => "0.0.5" })) }
      it "returns some missed, some hit" do
        expect(@missed).to eq(["D"].to_set)
        expect(@hit).to eq(pods.keys.to_set)
      end
    end

    context "no cache due to no prebuilt_lockfile" do
      let(:prebuilt_lockfile) { nil }
      it "returns all missed" do
        expect(@missed).to eq(pods.keys.to_set)
        expect(@hit).to be_empty
      end
    end

    context "incompatible settings" do
      let(:validate_prebuilt_settings) do
        lambda do |target|
          settings = {}
          settings["MACH_O_TYPE"] = "mh_dylib" if target == "A"
          settings["SWIFT_VERSION"] = "5.1" if target == "B"
          settings
        end
      end
      let(:generated_framework_path) { Pathname("GeneratedFrameworks") }
      it "returns incompatible cache as missed" do
        expect(@missed).to eq(Set["A", "B"])
        expect(@hit).to eq(pods.keys.to_set - Set["A", "B"])
      end
    end

    context "there are changes from Podfile" do
      let(:podfile) do
        Pod::Podfile.new do
          source "https://cdn.cocoapods.org/"
          pod "A", "0.0.6"  # Updated
          pod "B", "0.0.5"
          pod "C", "0.0.5"
          pod "D", "0.0.5"  # Added
        end
      end
      context "no Podfile.lock" do
        let(:pod_lockfile) { nil }
        it "checks against pods in Podfile" do
          expect(@missed).to eq(Set["A", "D"])
          expect(@hit).to eq(Set["B", "C"])
        end
      end

      context "exist changes in Podfile.lock" do
        let(:pod_lockfile) { gen_lockfile(pods: pods.merge("C" => { :version => "0.0.6" })) }
        it "treats changes as missed" do
          expect(@missed).to eq(Set["A", "C", "D"])
          expect(@hit).to eq(Set["B"])
        end
      end
    end

    context "has ignored_pods" do
      let(:pod_lockfile) do
        merged_pods = pods.merge(
          "A" => { :version => "0.0.1" }, # outdated
          "D" => { :version => "0.0.5" } # not present
        )
        gen_lockfile(pods: merged_pods)
      end
      let(:ignored_pods) { Set["B", "D"] }
      it "excludes them from the result" do
        expect(@missed).not_to include("B", "D")
        expect(@hit).not_to include("B", "D")
      end
    end

    context "has subspec pods" do
      let(:subspec_pods) do
        {
          "S/A" => { :version => "0.0.5" },
          "S/B" => { :version => "0.0.5" }
        }
      end
      let(:prebuilt_subspec_pods) do
        {
          "S/A" => { :version => "0.0.5" },
          "S/B" => { :version => "0.0.5" }
        }
      end
      let(:pod_lockfile) { gen_lockfile(pods: pods.merge(subspec_pods)) }
      let(:prebuilt_lockfile) { gen_lockfile(pods: pods.merge(prebuilt_subspec_pods)) }

      context "all subspec pods are hit" do
        it "returns the parent pod as hit" do
          expect(@missed).not_to include("S")
          expect(@hit).to include("S")
        end
      end

      context "a subspec pod is missing" do
        let(:prebuilt_subspec_pods) do
          { "S/A" => { :version => "0.0.5" } }
        end
        it "returns the parent pod as missed" do
          expect(@missed).to include("S")
          expect(@hit).not_to include("S")
        end
      end

      context "a subspec pod is outdated" do
        let(:prebuilt_subspec_pods) do
          {
            "S/A" => { :version => "0.0.5" },
            "S/B" => { :version => "0.0.4" }
          }
        end
        it "returns the parent pod as missed" do
          expect(@missed).to include("S")
          expect(@hit).not_to include("S")
        end
      end
    end
  end
end
