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
      uri = URI.parse(url)
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
end
