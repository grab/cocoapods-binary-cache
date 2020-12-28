require "cocoapods-binary-cache/pod-binary/integration/patch/source_installation"

describe "Pod::Installer::PrebuiltSourceInstaller" do
  describe "#install!" do
    let(:podfile) { Pod::Podfile.new }
    let(:tmp_dir) { create_tempdir }
    let(:sandbox) { Pod::Sandbox.new(tmp_dir) }
    let(:name) { "A" }
    before do
      @source_installer = Pod::Installer::PodSourceInstaller.new(sandbox, podfile, [])
      @installer = Pod::Installer::PrebuiltSourceInstaller.new(
        sandbox,
        podfile,
        [],
        source_installer: @source_installer
      )
      allow(@installer).to receive(:name).and_return(name)
      allow(@installer).to receive(:install_prebuilt_framework!)
    end

    after do
      FileUtils.remove_entry tmp_dir
    end

    describe "download sources" do
      it "downloads sources by default" do
        expect(@source_installer).to receive(:install!)
        @installer.install!
      end
    end
  end
end
