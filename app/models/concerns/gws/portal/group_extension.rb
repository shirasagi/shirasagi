module Gws::Portal::GroupExtension
  extend ActiveSupport::Concern

  included do
    has_one :portal_group_setting, class_name: 'Gws::Portal::GroupSetting',
      foreign_key: :portal_group_id, dependent: :destroy, inverse_of: :portal_group

    has_one :portal_root_setting, class_name: 'Gws::Portal::RootSetting',
      foreign_key: :portal_group_id, dependent: :destroy, inverse_of: :portal_group
  end

  def find_or_new_portal_group_setting(params = {})
    portal_group_setting || Gws::Portal::GroupSetting.new({
      portal_group_id: id,
      group_ids: [id]
    }.merge(params))
  end

  def find_or_new_portal_root_setting(params = {})
    portal_root_setting || Gws::Portal::RootSetting.new({
      portal_group_id: id,
      group_ids: [id]
    }.merge(params))
  end
end
