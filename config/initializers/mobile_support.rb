module SS
  module MobileSupport
    include SS::FilterSupport

    def mobile?(request)
      filters = request.env["ss.filters"] rescue nil
      return false if filters.blank?
      filters.include?(:mobile)
    end

    def mobile_path?(request, uri)
      return false if uri.path.blank?
      uri.path.start_with?(cur_site(request).mobile_url)
    end

    def embed_mobile_path(request, url)
      uri = URI.parse(url) rescue nil

      return url unless uri
      return url unless same_host?(request, uri)
      return url if relative_path?(request, uri)
      return url if mobile_path?(request, uri)
      return url if fs_path?(request, uri)
      uri.path = ::File.join(cur_site(request).mobile_url, uri.path.to_s.sub(cur_site(request).url, ""))
      uri.to_s
    end

    module_function :mobile?
    module_function :mobile_path?
    module_function :embed_mobile_path
  end

  module MobileRedirecting
    extend ActiveSupport::Concern

    def redirect_to(options = {}, response_status = {})
      super
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
  end
end

ActiveSupport.on_load(:action_controller) do
#  include SS::MobileUrlFor
  include SS::MobileRedirecting
end
