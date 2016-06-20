module SS
  module MobileSupport
    def mobile?(request)
      filters = request.env["ss.filters"]
      return false if filters.blank?
      filters.include?(:mobile)
    end

    def cur_site(request)
      request.env["ss.site"]
    end

    def same_host?(request, uri)
      return true unless uri.host
      site = cur_site(request)
      return false unless site
      return true if site.domains.include?(uri.host)
      return true if uri.port && site.domains.include?("#{uri.host}:#{uri.port}")
      false
    end

    def absolute_path?(_, uri)
      return false if uri.path.blank?
      uri.path.start_with?("/")
    end

    def relative_path?(request, uri)
      !absolute_path?(request, uri)
    end

    def mobile_path?(request, uri)
      return false if uri.path.blank?
      uri.path.start_with?("#{cur_site(request).mobile_location}/")
    end

    def fs_path?(_, uri)
      return false if uri.path.blank?
      uri.path.start_with?("/fs")
    end

    def embed_mobile_path(request, url)
      uri = URI.parse(url) rescue nil

      return url unless uri
      return url unless same_host?(request, uri)
      return url if relative_path?(request, uri)
      return url if mobile_path?(request, uri)
      return url if fs_path?(request, uri)
      uri.path = "#{cur_site(request).mobile_location}#{uri.path}"
      uri.to_s
    end

    module_function :mobile?
    module_function :cur_site
    module_function :same_host?
    module_function :absolute_path?
    module_function :relative_path?
    module_function :mobile_path?
    module_function :fs_path?
    module_function :embed_mobile_path
  end

  module MobileRedirecting
    extend ActiveSupport::Concern

    def redirect_to_with_shirasagi(options = {}, response_status = {})
      redirect_to_without_shirasagi(options, response_status)
      if SS::MobileSupport.mobile?(request)
        save_location = self.location
        self.location = SS::MobileSupport.embed_mobile_path(request, save_location)
        if save_location != location
          self.response_body = <<HTML
          <html><body>You are being <a href=\"#{ERB::Util.unwrapped_html_escape(location)}\">redirected</a>.</body></html>
HTML
        end
      end
    end

    included do
      alias_method_chain :redirect_to, :shirasagi
    end
  end
end

ActiveSupport.on_load(:action_controller) do
  # include SS::MobileUrlFor
  include SS::MobileRedirecting
end
