class Workflow::Route
  include Workflow::Model::Route
  include Cms::GroupPermission

  scope :site, ->(site) { self.in(group_ids: Cms::Group.site(site).pluck(:id)) }
end
