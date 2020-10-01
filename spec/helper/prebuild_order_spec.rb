describe "PodPrebuild::BuildOrder" do
  describe "#order_targets" do
    before do
      targets = [1, 3, 2].map do |n_deps|
        dependencies = (0...n_deps).map { |_| OpenStruct.new }
        OpenStruct.new(:id => n_deps, :recursive_dependent_targets => dependencies)
      end
      @ordered_targets = PodPrebuild::BuildOrder.order_targets(targets)
    end
    it "sorts targets with more dependencies first" do
      expect(@ordered_targets.map(&:id)).to eq([3, 2, 1])
    end
  end
end
