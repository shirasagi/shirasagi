module SS::Addon::SiteUsage
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :usage_node_count, type: Integer
    field :usage_page_count, type: Integer
    field :usage_file_count, type: Integer
    field :usage_db_size, type: Integer
    field :usage_group_count, type: Integer
    field :usage_user_count, type: Integer
    field :usage_calculated_at, type: DateTime
  end

  def reload_usage!
    now = Time.zone.now

    self.usage_node_count = Cms::Node.site(self).count
    self.usage_page_count = Cms::Page.site(self).count
    self.usage_file_count = SS::File.where(site_id: self.id).count
    self.usage_db_size = Cms.find_cms_quota_used(self.class.where(id: id))

    group_names = self.root_groups.pluck(:name)
    conditions = group_names.map { |name| { name: /^#{Regexp.escape(name)}(\/|$)/ } }
    groups = Cms::Group.all.unscoped.where("$and" => [{ "$or" => conditions }]).active
    self.usage_group_count = groups.count

    users = Cms::User.all.unscoped.in(group_ids: groups.pluck(:id)).active
    self.usage_user_count = users.count

    self.usage_calculated_at = now
    self.save!
  end
end
