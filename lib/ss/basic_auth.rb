class SS::BasicAuth
  class << self
    def find_by_domain(site)
      credentials(site)
    end

    def credentials(site)
      @@credentials ||= begin
        basic_auth_credentials(site).map do |item|
          [item["domain"], OpenStruct.new(item)]
        end.to_h
      end
    end

    def basic_auth_credentials(site)
      [{ "domain"=>site.kintone_domain, "user"=>site.kintone_user, "password"=>SS::Crypt.decrypt(site.kintone_password) }]
    end
  end
end
