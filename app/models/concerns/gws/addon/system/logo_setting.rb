module Gws::Addon::System::LogoSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include SS::Model::LogoSetting

  def logo_application_url
    url_helpers = Rails.application.routes.url_helpers

    return url_helpers.gws_portal_path(site: self) if logo_application_link == "portal"
    url_helpers.sns_mypage_path
  end

  set_addon_type :organization
end
