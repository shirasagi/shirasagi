class SS::Nginx::Configuration
  class << self
    def virtual_conf
      "#{Rails.root}/config/nginx.conf"
    end

    def partial_conf
      "conf.d/server/#{File.basename(Rails.root)}.conf"
    end

    def write
      conf = {}
      conf = cms_conf(conf) if SS.config.cms.disable.blank?
      conf = gws_conf(conf) if SS.config.gws.disable.blank?
      File.write(virtual_conf, conf.values.join("\n") + "\n")
      self
    end

    def reload_server
       `nginx -s reload`
       self
    end

    def cms_conf(conf = {})
      SS::Site.all.each do |site|
        site.domains.each do |domain|
          next if conf[domain]
          data = []
          data << "server {"
          data << "  include conf.d/server/#{partial_conf};"
          data << "  server_name #{domain};"
          data << "  root #{site.root_path};"
          data << "}"
          conf[domain] = data.join("\n")
        end
      end
      conf
    end

    def gws_conf(conf = {})
      SS::Group.where(:domains.exists => true).each do |group|
        group.domains.each do |domain|
          next if conf[domain]
          data = []
          data << "server {"
          data << "  include conf.d/server/#{partial_conf};"
          data << "  server_name #{domain};"
          data << "  root #{Rails.root}/public;"
          data << "}"
          conf[domain] = data.join("\n")
        end
      end
      conf
    end
  end
end
