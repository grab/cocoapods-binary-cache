# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

# Provide DSL options to set from Podfile
require_relative 'pod-binary/prebuild_dsl'

# Hook cocoapods pre-install and post-install to do prebuild, caching stuffs
require_relative 'pod-binary/prebuild_hook'