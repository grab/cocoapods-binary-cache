def gen_lockfile(options = {})
  hash = {}
  if options[:pods].class == Hash
    hash['PODS'] = options[:pods].map { |k, v| "#{k} (#{v})" }
    hash['DEPENDENCIES'] = options[:pods].keys
  else
    hash['PODS'] = options[:pods] || []
    hash['DEPENDENCIES'] = options[:dependencies] || []
  end
  hash['EXTERNAL SOURCES'] = options[:external_sources] || {}
  hash['SPEC CHECKSUMS'] = options[:spec_checksums] || {}
  hash['COCOAPODS'] = options[:cocoapods] || '1.7.5'
  Pod::Lockfile.new(hash)
end
