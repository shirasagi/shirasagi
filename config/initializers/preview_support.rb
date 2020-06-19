module SS
  module PreviewSupport
    include SS::FilterSupport

    def preview?(request)
      filters = request.env["ss.filters"] rescue nil
      return false if filters.blank?

      filters = filters.map do |filter|
        filter.is_a?(Hash) ? filter.keys : filter
      end.flatten.uniq
      filters.include?(:preview)
    end

    def preview_path?(request, uri)
      return false if uri.path.blank?

      routes = Rails.application.routes.url_helpers
      preview_path = routes.cms_preview_path(site: cur_site(request), path: "")

      uri.path.start_with?(preview_path)
    end

    def embed_preview_path(request, url)
      uri = URI.parse(url) rescue nil

      return url unless uri
      return url unless same_host?(request, uri)
      return url if relative_path?(request, uri)
      return url if preview_path?(request, uri)
      return url if fs_path?(request, uri)

      path = uri.path.sub(/^\//, "")
      routes = Rails.application.routes.url_helpers
      routes.cms_preview_path(site: cur_site(request), path: path)
    end

    module_function :preview?
    module_function :preview_path?
    module_function :embed_preview_path
  end

  module PreviewRedirecting
    extend ActiveSupport::Concern

    def redirect_to(options = {}, response_status = {})
      super
      if PreviewSupport.preview?(request)
        save_location = self.location
        self.location = SS::PreviewSupport.embed_preview_path(request, save_location)
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
  include SS::PreviewRedirecting
end
