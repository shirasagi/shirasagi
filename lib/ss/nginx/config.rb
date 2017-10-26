class SS::Nginx::Config
  attr_reader :virtual_conf, :partial_conf, :written

  def initialize
    @virtual_conf = "#{Rails.root}/config/nginx.conf"
    @partial_conf = "conf.d/server/#{::File.basename(Rails.root)}.conf"
    @written = false
    @data = ::File.read(@virtual_conf) if ::File.exist?(@virtual_conf)
  end

  def write
    conf = {}
    conf = cms_conf(conf) if SS.config.cms.disable.blank?
    conf = gws_conf(conf) if SS.config.gws.disable.blank?
    data = conf.values.join("\n") + "\n"

    if @data != data
      ::File.write(@virtual_conf, data)
      @written = true
    end
    self
  end

  def reload_server
    if @written
      `nginx -s reload`
    end
    self
  end

  def reload_server!
    `nginx -s reload`
    self
  end

  def cms_conf(conf = {})
    SS::Site.all.each do |site|
      site.domains.each do |domain|
        next if conf[domain]
        domain_name, port = domain.split(':')
        data = []
        data << "server {"
        data << "  include #{@partial_conf};"
        data << "  server_name #{domain};"
        data << "  listen #{port};" if port
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
        domain_name, port = domain.split(':')
        data = []
        data << "server {"
        data << "  include #{@partial_conf};"
        data << "  listen #{port};" if port
        data << "  server_name #{domain_name};"
        data << "  root #{Rails.root}/public;"
        data << "}"
        conf[domain] = data.join("\n")
      end
    end
    conf
  end
end
