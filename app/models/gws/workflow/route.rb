class Gws::Workflow::Route
  include ::Workflow::Model::Route
  include Gws::SitePermission

  cattr_reader(:approver_user_class) { Gws::User }

  set_permission_name "gws_users", :edit

  scope :site, ->(site) { self.in(group_ids: Gws::Group.site(site).pluck(:id)) }
end
