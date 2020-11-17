require 'open-uri'

module OpenURI
  def self.open_uri_with_proxy(name, *rest, &block)
    proxy_uri = SS.config.proxy.proxy_http_basic_authentication["proxy_uri"]
    proxy_username = SS.config.proxy.proxy_http_basic_authentication["proxy_username"]
    proxy_password = SS.config.proxy.proxy_http_basic_authentication["proxy_password"]
    proxy_password = SS::Crypt.decrypt(proxy_password) || proxy_password if proxy_password.present?
    ssl_verify_mode = SS.config.proxy.ssl_verify_mode

    options = rest.first || {}
    if options.is_a?(Hash)
      options.symbolize_keys!
      if proxy_uri.present?
        options.delete(:proxy)
        options.delete(:proxy_http_basic_authentication)

        if proxy_username.present? || proxy_password.present?
          options[:proxy_http_basic_authentication] = [ proxy_uri, proxy_username, proxy_password ]
        else
          options[:proxy] = proxy_uri
        end
      end

      if ssl_verify_mode.present? && OpenSSL::SSL.constants.include?(ssl_verify_mode.to_sym)
        options[:ssl_verify_mode] = "OpenSSL::SSL::#{ssl_verify_mode}".constantize
      end
    end

    open_uri_without_proxy name, options, &block
  end

  class << self
    if !SS.config.proxy.disable
      alias open_uri_without_proxy open_uri
      alias open_uri open_uri_with_proxy
    end
  end
end
