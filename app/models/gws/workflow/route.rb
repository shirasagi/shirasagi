class Gws::Workflow::Route
  include ::Workflow::Model::Route
  include Gws::Referenceable
  include Gws::GroupPermission
  include Gws::Addon::History

  cattr_reader(:approver_user_class) { Gws::User }

  attr_accessor :cur_site, :cur_user

  scope :site, ->(site) { self.in(group_ids: Gws::Group.site(site).pluck(:id)) }
end
