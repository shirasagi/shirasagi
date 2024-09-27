module Gws::Workflow2::DestinationSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    embeds_ids :destination_groups, class_name: "Gws::Group"
    embeds_ids :destination_users, class_name: "Gws::User"
  end

  def workflow_destination_users
    user_ids = Gws::User.all.active.in(group_ids: destination_group_ids).pluck(:id)
    user_ids += destination_user_ids
    user_ids.uniq!
    approver_user_class.site(@cur_site || self.site).in(id: user_ids)
  end
end
