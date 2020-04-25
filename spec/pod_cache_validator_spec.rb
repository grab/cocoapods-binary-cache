describe 'PodCacheValidator' do
  describe 'verify prebuilt vendor pods' do
    let(:pods) { {'A' => '0.0.5', 'B' => '0.0.5', 'C' => '0.0.5'} }
    let(:pod_lockfile) { gen_lockfile(pods: pods) }
    let(:pod_bin_lockfile) { gen_lockfile(pods: pods) }
    before do
      @missed, @hit = PodCacheValidator.verify_prebuilt_vendor_pods(pod_lockfile, pod_bin_lockfile)
    end

    context 'all cache hits' do
      it 'returns non missed, all hit' do
        expect(@missed).to be_empty
        expect(@hit).to eq(pods.keys.to_set)
      end
    end

    context 'some cache miss due to outdated' do
      let(:pod_lockfile) { gen_lockfile(pods: pods.merge('A' => '0.0.1')) }
      it 'returns some missed, some hit' do
        expect(@missed).to eq(['A'].to_set)
        expect(@hit).to eq(pods.keys.to_set - ['A'])
      end
    end

    context 'some cache miss due to not present' do
      let(:pod_lockfile) { gen_lockfile(pods: pods.merge('D' => '0.0.5')) }
      it 'returns some missed, some hit' do
        skip 'code does not pass this test' # TODO (thuyen): Fix code

        expect(@missed).to eq(['D'].to_set)
        expect(@hit).to eq(pods.keys.to_set)
      end
    end

    context 'no cache due to no pod_bin_lockfile' do
      let(:pod_bin_lockfile) { nil }
      it 'returns all missed' do
        expect(@missed).to eq(pods.keys.to_set)
        expect(@hit).to be_empty
      end
    end
  end
end
