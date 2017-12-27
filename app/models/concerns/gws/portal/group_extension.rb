module Gws::Portal::GroupExtension
  extend ActiveSupport::Concern

  included do
    has_one :portal_setting, class_name: 'Gws::Portal::GroupSetting',
      foreign_key: :portal_group_id, dependent: :destroy, inverse_of: :portal_group
  end

  def find_portal_setting(params = {})
    portal = portal_setting || Gws::Portal::GroupSetting.new({
      site_id: params[:cur_site].id,
      portal_group_id: id,
      readable_group_ids: [id],
      group_ids: [id]
    })
    portal.attributes = params
    portal
  end
end
