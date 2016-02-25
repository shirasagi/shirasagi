class Gws::Workflow::Route
  include ::Workflow::Model::Route
  include Gws::GroupPermission

  cattr_reader(:approver_user_class) { Gws::User }

  scope :site, ->(site) { self.in(group_ids: Gws::Group.site(site).pluck(:id)) }
end
