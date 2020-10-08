# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

require "rexml/document"

class SchemeEditor
  def self.edit_to_support_code_coverage(sandbox)
    pod_proj_path = sandbox.project_path
    Pod::UI.message "Modify schemes of pod project to support code coverage of prebuilt local pod: #{pod_proj_path}"
    scheme_files = Dir["#{pod_proj_path}/**/*.xcscheme"]
    scheme_files.each do |file_path|
      scheme_name = File.basename(file_path, ".*")
      next unless sandbox.local?(scheme_name)

      Pod::UI.message "Modify scheme to enable coverage symbol when prebuild: #{scheme_name}"

      doc = File.open(file_path, "r") { |f| REXML::Document.new(f) }
      scheme = doc.elements["Scheme"]
      test_action = scheme.elements["TestAction"]
      next if test_action.attributes["codeCoverageEnabled"] == "YES"

      test_action.add_attribute("codeCoverageEnabled", "YES")
      test_action.add_attribute("onlyGenerateCoverageForSpecifiedTargets", "YES")
      coverage_targets = REXML::Element.new("CodeCoverageTargets")
      buildable_ref = scheme
        .elements["BuildAction"]
        .elements["BuildActionEntries"]
        .elements["BuildActionEntry"]
        .elements["BuildableReference"]
      new_buildable_ref = buildable_ref.clone # Need to clone, otherwise the original one will be move to new place
      coverage_targets.add_element(new_buildable_ref)
      test_action.add_element(coverage_targets)
      File.open(file_path, "w") { |f| doc.write(f) }
    end
  end
end
