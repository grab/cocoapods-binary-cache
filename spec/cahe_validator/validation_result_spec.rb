describe "PodPrebuild::CacheValidationResult" do
  describe "merge behavior" do
    let(:one) { [{ "A" => "missing" }, Set["X"]] }
    let(:another) { [{ "C" => "outdated" }, Set["Y"]] }
    before do
      @merged = PodPrebuild::CacheValidationResult.new(*one).merge(
        PodPrebuild::CacheValidationResult.new(*another)
      )
    end

    it "returns correct result" do
      expect(@merged.missed).to eq(Set["A", "C"])
      expect(@merged.hit).to eq(Set["X", "Y"])
    end

    context "a pod appears in both hit and missed" do
      let(:another) { [{ "X" => "outdated" }, Set["Y"]] }
      it "treats that pod as missed" do
        expect(@merged.missed).to eq(Set["A", "X"])
        expect(@merged.hit).to eq(Set["Y"])
      end
    end
  end

  describe "exclude_pods behavior" do
    let(:data) do
      cache_miss = { "A" => "missing", "B" => "missing", "B/Sub" => "missing", "B/AnotherSub" => "missing" }
      cache_hit = Set["X", "Y", "Y/Sub", "Y/AnotherSub"]
      [cache_miss, cache_hit]
    end
    let(:excluded_pods) { Set.new }
    before do
      @excluded = PodPrebuild::CacheValidationResult.new(*data).exclude_pods(excluded_pods)
    end

    context "excludes pods without subspec" do
      let(:excluded_pods) { Set["A", "X"] }

      it "excludes matched pods" do
        expect(@excluded.missed).to eq(Set["B", "B/Sub", "B/AnotherSub"])
        expect(@excluded.hit).to eq(Set["Y", "Y/Sub", "Y/AnotherSub"])
      end
    end

    context "excludes pod that has subspec" do
      let(:excluded_pods) { Set["B", "Y"] }

      it "excludes all subspecs and the parent pod" do
        expect(@excluded.missed).to eq(Set["A"])
        expect(@excluded.hit).to eq(Set["X"])
      end
    end

    context "excludes a subspec" do
      let(:excluded_pods) { Set["B/Sub", "Y/Sub"] }

      it "excludes all subspecs and the parent pod" do
        expect(@excluded.missed).to eq(Set["A"])
        expect(@excluded.hit).to eq(Set["X"])
      end
    end
  end
end
