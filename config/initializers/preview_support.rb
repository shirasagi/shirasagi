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

      routes = Rails.application.routes.url_helpers
      routes.cms_preview_path(site: cur_site(request), path: url.sub(/^\//, ""))
    end

    module_function :preview?
    module_function :preview_path?
    module_function :embed_preview_path
  end
end
