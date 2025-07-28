module Gws::Addon::Facility::DefaultMemberSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :default_members, class_name: "Gws::User"
    permit_params default_member_ids: []
  end
end
