require 'oauth2'

module OAuth::Base
  def site
    @site ||= begin
      request.env["ss.site"] ||= begin
        host = request.env["HTTP_X_FORWARDED_HOST"] || request.env["HTTP_HOST"] || request.host_with_port
        path = request.env["REQUEST_PATH"] || request.path
        SS::Site.find_by_domain host, path
      end
    end
  end

  def node
    return if site.blank?
    @node ||= begin
      request.env["ss.node"] ||= begin
        path = request.env["REQUEST_PATH"] || request.path
        if site.subdir.present?
          main_path = path.sub(/^\/#{site.subdir}/, "")
        else
          main_path = path.dup
        end

        Member::Node::Login.site(site).in_path(main_path).reorder(depth: -1).first
      end
    end
  end

  def client_id
    @client_id ||= begin
      id = node.try("#{name}_client_id".downcase)
      id = SS.config.oauth.try(:[], "#{name}_client_id") if id.blank?
      id
    end
  end

  def client_secret
    @client_secret ||= begin
      secret = node.try("#{name}_client_secret".downcase)
      secret = SS.config.oauth.try(:[], "#{name}_client_secret") if secret.blank?
      secret
    end
  end

  # override OmniAuth::Strategies::OAuth2#client
  def client
    ::OAuth2::Client.new(client_id, client_secret, deep_symbolize(options.client_options))
  end
end
