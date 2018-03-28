module OpenURI
  class << self
    alias_method :open_uri_without_proxy, :open_uri
  end

  def self.open_uri(name, *rest, &block)
    if !SS.config.open_uri_proxy.disable
      proxy_uri = SS.config.open_uri_proxy.proxy_http_basic_authentication["proxy_uri"]
      proxy_username = SS.config.open_uri_proxy.proxy_http_basic_authentication["proxy_username"]
      proxy_password = SS.config.open_uri_proxy.proxy_http_basic_authentication["proxy_password"]

      options = rest.first || {}
      if options.kind_of?(Hash)
        options.symbolize_keys!
        options.delete(:proxy)
        options[:proxy_http_basic_authentication] = [proxy_uri, proxy_username, proxy_password]

        options.delete(:ssl_verify_mode)
        options[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE

        rest = [options]
      end
    end
    open_uri_without_proxy name, *rest, &block
  end
end
