module Gws::Addon::Workflow2::RouteReadableSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::ReadableSetting

  included do
    validate :validate_readable_setting_range
  end

  private

  def validate_readable_setting_range
    return if readable_setting_range == 'private'
    return unless @cur_site
    return unless @cur_user

    unless @cur_user.gws_role_permit_any?(@cur_site, :public_readable_range_gws_workflow2_routes)
      errors.add :base, :readable_setting_range_error
    end
  end
end
