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

    def same_site?(request, uri)
      site = cur_site(request)
      return false unless site
      return false if uri.path.blank?
      site.id == site.same_domain_site_from_path(uri.path).try(:id)
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
  end
end
