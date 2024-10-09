# 本来 Unicorn 6.1.0 は Rack 3 に対応していないので、Unicorn 6.1.0 を Rack 3 に対応させるための monkey patch
if Module.const_defined?(:Unicorn) && Unicorn::Const::UNICORN_VERSION == "6.1.0"
  module Unicorn
    module HttpResponse

      def append_header(buf, key, value)
        case value
        when Array # Rack 3
          value.each { |v| buf << "#{key}: #{v}\r\n" }
        when /\n/ # Rack 2
          # avoiding blank, key-only cookies with /\n+/
          value.split(/\n+/).each { |v| buf << "#{key}: #{v}\r\n" }
        else
          buf << "#{key}: #{value}\r\n"
        end
      end

      def http_response_write(socket, status, headers, body, req = Unicorn::HttpRequest.new)
        hijack = nil

        if headers
          code = status.to_i
          msg = STATUS_CODES[code]
          start = req.response_start_sent ? ''.freeze : 'HTTP/1.1 '.freeze
          buf = "#{start}#{msg ? %Q(#{code} #{msg}) : status}\r\n" \
            "Date: #{httpdate}\r\n" \
            "Connection: close\r\n"
          headers.each do |key, value|
            case key
            when %r{\A(?:Date|Connection)\z}i
              next
            when "rack.hijack"
              # This should only be hit under Rack >= 1.5, as this was an illegal
              # key in Rack < 1.5
              hijack = value
            else
              append_header(buf, key, value)
            end
          end
          socket.write(buf << "\r\n".freeze)
        end

        if hijack
          req.hijacked!
          hijack.call(socket)
        else
          body.each { |chunk| socket.write(chunk) }
        end
      end
    end
  end
end
