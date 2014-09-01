# coding: utf-8
module SS
  module Debug
    class << self
      public
        def dump(data, lev = 1)
          s = []
          if data.kind_of?(Array)
            s << "<#{data.class}> ["
            if data.size > 0
              s << "\n"
              data.each_with_index {|v, k| s << ("  " * lev) + "#{k} \t=> #{dump(v, lev + 1)}\n" }
              s << ("  " * (lev-1))
            end
            s << "]"
          elsif data.kind_of?(Hash)
            s << "<#{data.class}> {"
            if data.size > 0
              s << "\n"
              data.each {|k, v| s << ("  " * lev) + "#{k} \t=> #{dump(v, lev + 1)}\n" }
              s << ("  " * (lev-1))
            end
            s << "}"
          else
            s << "#{data} <#{data.class}>"
          end
          return s.join if lev > 1

          ::File.open("#{Rails.root}/log/dump.log", "a") {|f| f.puts s.join.force_encoding("utf-8") }
        end

        def bm(n = 1, &block)
          require 'benchmark'
          time = Benchmark.realtime { n.times { yield } }
          dump "#{sprintf("%.6f ms", time/n)} (#{sprintf("%.3f ms", time)}/#{n})"
        end
    end
  end
end