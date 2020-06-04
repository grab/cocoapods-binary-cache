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
end
