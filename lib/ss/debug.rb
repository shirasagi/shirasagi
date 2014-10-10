module SS
  module Debug
    class << self
      public
        def dump(data, lev = 1)
          s = []

          if data.kind_of?(Array)
            s << "<#{data.class}> [#{scan_array(data, lev)}]"
          elsif data.kind_of?(Hash)
            s << "<#{data.class}> {#{scan_hash(data, lev)}}"
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

      private
        def indent(lev)
          "  " * lev
        end

        def scan_array(data, lev)
          return "" if data.size == 0
          str = data.each_with_index.map { |v, k| scan_each k, v, lev }.join
          "\n#{str}#{indent(lev - 1)}"
        end

        def scan_hash(data, lev)
          return "" if data.size == 0
          str = data.map { |k, v| scan_each k, v, lev }.join
          "\n#{str}#{indent(lev - 1)}"
        end

        def scan_each(k, v, lev)
          "#{indent(lev)}#{k} \t=> #{dump(v, lev + 1)}\n"
        end
    end
  end
end