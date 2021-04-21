module SS
  module FilterSupport
    extend ActiveSupport::Concern

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

    def fs_path?(_, uri)
      return false if uri.path.blank?
      uri.path.start_with?("/fs")
    end

    def sns_redirect_path?(_, uri)
      return false if uri.path.blank?
      uri.path.start_with?("/.mypage/redirect")
    end

    included do
      module_function :cur_site
      module_function :same_host?
      module_function :absolute_path?
      module_function :relative_path?
      module_function :fs_path?
      module_function :sns_redirect_path?
    end
  end
end
