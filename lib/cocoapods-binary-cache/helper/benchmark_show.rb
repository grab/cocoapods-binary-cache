# Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
# Use of this source code is governed by an MIT-style license that can be found in the LICENSE file

require "benchmark"

class BenchmarkShow
  def self.benchmark
    time = Benchmark.measure { yield }
    Pod::UI.puts "🕛 Time elapsed: #{time}"
  end
end
