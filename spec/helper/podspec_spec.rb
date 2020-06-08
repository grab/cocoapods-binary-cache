describe "Specification" do
  describe "#empty_source_files?" do
    it "returns true if #source_files is not specified and is empty" do
      spec = Pod::Specification.new
      expect(spec.empty_source_files?).to be true

      spec = Pod::Specification.new { |s| s.source_files = [] }
      expect(spec.empty_source_files?).to be true

      spec = Pod::Specification.new { |s| s.source_files = "" }
      expect(spec.empty_source_files?).to be true
    end

    it "returns true if #source_files only contains headers" do
      spec = Pod::Specification.new { |s| s.source_files = ["path/to/*.h"] }
      expect(spec.empty_source_files?).to be true

      spec = Pod::Specification.new { |s| s.source_files = "path/to/*.hpp" }
      expect(spec.empty_source_files?).to be true
    end

    it "returns false if #source_files contains non-header files" do
      spec = Pod::Specification.new { |s| s.source_files = ["path/to/*.swift"] }
      expect(spec.empty_source_files?).to be false

      spec = Pod::Specification.new { |s| s.source_files = "path/to/*.swift" }
      expect(spec.empty_source_files?).to be false
    end

    context "multi-platforms" do
      it "returns false if exists a platform containing non-header files" do
        spec = Pod::Specification.new do |s|
          s.ios.source_files = []
          s.tvos.source_files = "path/to/*.hpp"
          s.osx.source_files = ["path/to/*.swift"]
        end
        expect(spec.empty_source_files?).to be false
      end

      it "returns true if all platforms satisfy" do
        spec = Pod::Specification.new do |s|
          s.ios.source_files = []
          s.tvos.source_files = ""
          s.osx.source_files = [""]
        end
        expect(spec.empty_source_files?).to be true
      end
    end

    context "has subspecs" do
      it "returns true if all subspecs have empty source files" do
        spec = Pod::Specification.new do |s|
          s.subspec("A") { |ss| ss.source_files = [] }
          s.subspec("B") { |ss| ss.source_files = ["path/to/*.h"] }
        end
        expect(spec.empty_source_files?).to be true
      end

      it "returns false if exists a subspec having source files" do
        spec = Pod::Specification.new do |s|
          s.subspec("A") { |ss| ss.source_files = [] }
          s.subspec("B") { |ss| ss.source_files = ["path/to/*.swift"] }
        end
        expect(spec.empty_source_files?).to be false
      end
    end
  end
end
