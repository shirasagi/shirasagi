class SS::BasicAuth
  class << self
    def find_by_domain(domain)
      credentials[domain]
    end

    def credentials
      @@credentials ||= begin
        SS.config.basic_auth.credentials.to_a.map do |item|
          [item["domain"], OpenStruct.new(item)]
        end.to_h
      end
    end
  end
end
