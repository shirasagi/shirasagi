module Gws::Portal::GroupExtension
  extend ActiveSupport::Concern

  included do
    has_many :portal_setting, class_name: 'Gws::Portal::GroupSetting',
      foreign_key: :portal_group_id, dependent: :destroy, inverse_of: :portal_group
  end

  def find_portal_setting(params = {})
    site = params[:cur_site]
    portal = portal_setting.site(site).first || Gws::Portal::GroupSetting.new(
      {
        site_id: site.id,
        portal_group_id: id,
        readable_setting_range: organization? ? "public" : "select",
        readable_group_ids: organization? ? [] : [id],
        group_ids: [id]
      }
    )
    portal.name = trailing_name
    portal.attributes = params
    portal
  end
end
