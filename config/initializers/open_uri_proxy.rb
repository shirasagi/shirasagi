require 'open-uri'

module OpenURI
  def self.open_uri_with_proxy(name, *rest, &block)
    options = rest.first || {}
    if options.is_a?(Hash)
      options.symbolize_keys!
      if SS::ProxySetting.instance.uri.present?
        options.delete(:proxy)
        options.delete(:proxy_http_basic_authentication)

        if SS::ProxySetting.instance.username.present? || SS::ProxySetting.instance.password.present?
          options[:proxy_http_basic_authentication] = [
            SS::ProxySetting.instance, SS::ProxySetting.instance.username, SS::ProxySetting.instance.password ]
        else
          options[:proxy] = SS::ProxySetting.instance
        end
      end

      verify_mode = SS::ProxySetting.instance.ssl_verify_mode_constant
      options[:ssl_verify_mode] = verify_mode if verify_mode
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
