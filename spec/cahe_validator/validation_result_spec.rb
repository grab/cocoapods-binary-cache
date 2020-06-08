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
      cache_miss = { "A" => "missing", "B" => "missing", "C" => "missing", "C/Sub" => "missing" }
      cache_hit = Set["X", "Y", "Z/Sub"]
      [cache_miss, cache_hit]
    end
    before do
      @excluded = PodPrebuild::CacheValidationResult.new(*data).exclude_pods(Set["B", "C", "Y", "Z"])
    end

    it "excludes pods with/without subspec and keeps correct pods" do
      expect(@excluded.missed).to eq(Set["A"])
      expect(@excluded.hit).to eq(Set["X"])
    end
  end
end
