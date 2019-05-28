module Workflow::MemberPermission
  extend ActiveSupport::Concern

  def allowed?(action, user, opts = {})
    user = user.cms_user
    site = opts[:site] || @cur_site
    node = opts[:node] || @cur_node

    action = permission_action || action
    if new_record?
      is_owned = node ? node.owned?(user) : false
    else
      is_owned = owned?(user)
    end

    permits = ["#{action}_other_#{self.class.permission_name}"]
    permits << "#{action}_private_#{self.class.permission_name}" if is_owned
    permits << "#{action}_member_#{self.class.permission_name}" if workflow_member_id.present?

    user.cms_role_permit_any?(site, permits)
  end

  module ClassMethods
    def allow(action, user, opts = {})
      site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]
      action = permission_action || action
      permit = "#{action}_other_#{permission_name}"
      level = user.cms_roles.where(site_id: site_id).in(permissions: permit).pluck(:permission_level).max
      s = super
      return s if level

      permit = "#{action}_member_#{permission_name}"
      level = user.cms_roles.where(site_id: site_id).in(permissions: permit).pluck(:permission_level).max
      non_members = s.where(:workflow_member_id => nil)
      non_members unless level

      members = self.where(:workflow_member_id.exists => true).where(permission_level: {"$lte" => level })
      with_scope(Mongoid::Criteria.new(self)) do
        self.where("$or" => [non_members.selector, members.selector])
      end
    end
  end
end
