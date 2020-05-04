def gen_lockfile(options = {})
  hash = {}
  pods_options = options[:pods].map do |name, pod|
    pod_ = pod.clone
    pod_[:name] = name
    pod_[:version] ||= "0.0.1"
    [name, pod_]
  end.to_h

  pods = pods_options.values
  hash["PODS"] = pods.map { |pod| gen_pod_item(pod) }
  hash["DEPENDENCIES"] = pods.map { |pod| gen_dependencies_item(pod) }
  hash["EXTERNAL SOURCES"] = pods_options[:external_sources] \
    || pods_options.select { |_, pod| pod.key?(:path) || pod.key?(:git) } \
                   .map { |name, pod| [name, gen_external_sources_item(pod)] }.to_h
  hash["SPEC CHECKSUMS"] = pods_options[:spec_checksums] || {}
  hash["COCOAPODS"] = pods_options[:cocoapods] || "1.7.5"
  Pod::Lockfile.new(hash)
end

private

def gen_pod_item(pod)
  name_with_version = "#{pod[:name]} (#{pod[:version]})"
  pod[:dependencies].nil? ? name_with_version : { pod[:name_with_version] => pod[:dependencies] }
end

def gen_dependencies_item(pod)
  source = begin
    return "from #{pod[:path]}" unless pod[:path].nil?

    unless pod[:git].nil?
      return "from #{pod[:git]}, tag: #{pod[:tag]}" unless pod[:tag].nil?
      return "from #{pod[:git]}, branch: #{pod[:branch]}" unless pod[:branch].nil?
      return "from #{pod[:git]}, commit: #{pod[:commit]}" unless pod[:commit].nil?
    end
    "= #{pod[:version]}"
  end
  "#{pod[:name]} (#{source})"
end

def gen_external_sources_item(pod)
  return { :path => pod[:path] } unless pod[:path].nil?
  return { :git => pod[:git], :tag => pod[:tag] } unless pod[:tag].nil?
  return { :git => pod[:git], :tag => pod[:branch] } unless pod[:branch].nil?
  return { :git => pod[:git], :commit => pod[:commit] } unless pod[:commit].nil?

  { :git => pod[:git] }
end
