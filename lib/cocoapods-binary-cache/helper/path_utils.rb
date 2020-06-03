# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

class PathUtils
  def self.remove_last_path_component(path, num_components = 1)
    path.split("/")[0...-num_components].join("/")
  end
end
