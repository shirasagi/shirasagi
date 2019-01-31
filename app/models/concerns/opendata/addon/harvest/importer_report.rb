module Opendata::Addon::Harvest
  module ImporterReport
    extend SS::Addon
    extend ActiveSupport::Concern

    def get_size_in_head(url)
      conn = ::Faraday::Connection.new(url: url)
      res = conn.head { |req| req.options.timeout = 10 }
      raise "Faraday conn.head timeout #{url}" unless res.success?

      headers = res.headers.map { |k, v| [k.downcase, v] }.to_h

      size = 0
      if headers["content-length"]
        size = headers["content-length"].to_i
      elsif headers["content-range"]
        size = headers["content-range"].scan(/\/(\d+)$/).flatten.first.to_i
      end

      size
    end
  end
end
