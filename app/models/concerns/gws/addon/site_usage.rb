module Gws::Addon::SiteUsage
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :usage_file_count, type: Integer
    field :usage_db_size, type: Integer
    field :usage_group_count, type: Integer
    field :usage_user_count, type: Integer
    field :usage_calculated_at, type: DateTime
  end

  def reload_usage!
    now = Time.zone.now

    self.usage_file_count = SS::File.where(owner_item_type: /^Gws::/).count
    self.usage_db_size = Gws.find_gws_quota_used(self.class.where(id: id))

    groups = Gws::Group.all.unscoped.where(name: /^#{Regexp.escape(self.name)}(\/|$)/).active
    self.usage_group_count = groups.count

    users = Gws::User.all.unscoped.in(group_ids: groups.pluck(:id)).active
    self.usage_user_count = users.count

    self.usage_calculated_at = now
    self.save!
  end
end
