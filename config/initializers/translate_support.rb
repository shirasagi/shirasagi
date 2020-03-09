module SS
  module TranslateSupport
    include SS::FilterSupport

    def translate?(request)
      filters = request.env["ss.filters"] rescue nil
      return false if filters.blank?
      filters.include?(:translate)
    end

    def translate_path?(request, uri)
      return false if uri.path.blank?
      uri.path.start_with?(cur_site(request).translate_url)
    end

    def translate_target(request)
      request.env["ss.translate_target"]
    end

    def embed_translate_path(request, url)
      uri = URI.parse(url) rescue nil

      return url unless uri
      return url unless same_host?(request, uri)
      return url if relative_path?(request, uri)
      return url if translate_path?(request, uri)
      return url if fs_path?(request, uri)
      uri.path = ::File.join(cur_site(request).translate_url, translate_target(request), uri.path.to_s.sub(cur_site(request).url, ""))
      uri.to_s
    end

    module_function :translate?
    module_function :translate_path?
    module_function :translate_target
    module_function :embed_translate_path
  end

  module TranslateRedirecting
    extend ActiveSupport::Concern

    def redirect_to(options = {}, response_status = {})
      super
      if SS::TranslateSupport.translate?(request)
        save_location = self.location
        self.location = SS::TranslateSupport.embed_translate_path(request, save_location)
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
  include SS::TranslateRedirecting
end
