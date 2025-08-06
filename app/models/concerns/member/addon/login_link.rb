module Member::Addon::LoginLink
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :login_link_url, type: String
    permit_params :login_link_url
    validates :login_link_url, "sys/trusted_url" => true, if: ->{ Sys::TrustedUrlValidator.url_restricted? }
  end

  def find_login_link_url
    ret = self.login_link_url.presence
    return ret if ret

    ret = self.parent.url.presence rescue nil
    return ret if ret

    ret = Member::Node::Mypage.site(@cur_site || self.site).and_public.first.url rescue nil
    return ret if ret

    ret = Member::Node::Login.site(@cur_site || self.site).and_public.first.url rescue nil
    return ret if ret

    @cur_site.url
  end
end
