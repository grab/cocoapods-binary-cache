# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

class PrebuildConfig
  @CONFIGURATION = 'Debug'

  class << self
    attr_accessor :CONFIGURATION
  end
end
