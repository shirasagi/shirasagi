class Gws::Affair2::Workflow::Route
  include ::Workflow::Model::Route
  include ::Workflow::Addon::ApproverView
  include ::Workflow::Addon::CirculationView
  include Gws::Referenceable
  include Gws::Addon::History
  include Gws::SitePermission

  cattr_reader(:approver_user_class) { Gws::User }

  set_permission_name 'gws_affair2_workflow_routes', :use

  attr_accessor :cur_site

  class << self
    def site(site)
      user_ids = Gws::User.site(site).pluck(:id)
      self.in(user_id: user_ids)
    end
  end
end
