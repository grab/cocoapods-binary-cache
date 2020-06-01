describe "PodPrebuild::CacheValidationResult" do
  describe "merge behavior" do
    let(:one) { PodPrebuild::CacheValidationResult.new({ "A" => "missing" }, Set["X"]) }
    let(:another) { PodPrebuild::CacheValidationResult.new({ "C" => "outdated" }, Set["Y"]) }

    it "returns correct result" do
      result = one.merge(another)
      expect(result.missed).to eq(Set["A", "C"])
      expect(result.hit).to eq(Set["X", "Y"])
    end
  end
end
