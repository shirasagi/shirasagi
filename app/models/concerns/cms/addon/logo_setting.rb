module Cms::Addon::LogoSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include SS::Model::LogoSetting

  def logo_application_url
    url_helpers = Rails.application.routes.url_helpers

    return url_helpers.cms_contents_path(site: self) if logo_application_link == "portal"
    url_helpers.sns_mypage_path
  end
end
