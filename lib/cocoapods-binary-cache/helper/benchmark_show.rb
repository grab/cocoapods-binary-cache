require 'benchmark'

class BenchmarkShow
  def self.benchmark
    time = Benchmark.measure { yield }
    puts "🕛 Time elapsed: #{time}"
  end
end