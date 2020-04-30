describe "JSONFile" do
  let(:data) { { "a" => 1, "b" => 2 } }
  let(:file) { create_tempfile("sample.json", content: data.to_json) }
  before do
    @json = PodPrebuild::JSONFile.new(file.path)
  end
  after do
    file.unlink
  end

  describe "initialization" do
    context "file not exist" do
      let(:file) do
        f = create_tempfile("sample.json")
        FileUtils.rm_rf(f)
        f
      end
      it "represents empty data" do
        expect(@json.data).to be_empty
      end
    end

    context "file exist with non-empty content" do
      it "parses correct data" do
        expect(@json.data).to eq(data)
      end
    end
  end

  describe "data update" do
    let(:should_save) { true }
    before do
      @json["c"] = 3
      @json.save! if should_save
      @reloaded_json = PodPrebuild::JSONFile.new(file.path)
    end
    context "without saving" do
      let(:should_save) { false }
      it "does not serialize data to persistent" do
        expect(@reloaded_json.data).to eq(data)
      end
    end

    context "when saving" do
      it "serializes updated data to persistent" do
        expect(@reloaded_json.data).to eq(data.merge("c" => 3))
      end
    end
  end
end
