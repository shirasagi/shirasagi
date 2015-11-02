module Workflow::MemberPermission
  extend ActiveSupport::Concern

  public
    def allowed?(action, user, opts = {})
      opts.merge!(access: :member) if workflow_member_id.present?
      super(action, user, opts)
    end

  module ClassMethods
    public
      def allow(action, user, opts = {})
        s = super
        return s unless s.selector["_id"].present?
        return s unless s.selector["group_ids"].present?

        site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]
        non_members = s.where(:workflow_member_id => nil)
        action = permission_action || action
        permit = "#{action}_member_#{permission_name}"
        level = user.cms_roles.where(site_id:  site_id).in(permissions: permit).pluck(:permission_level).max

        non_members unless level
        members = self.where(:workflow_member_id.exists => true).where(permission_level: {"$lte" => level })
        with_scope(Mongoid::Criteria.new(self)) do
          self.where("$or" => [non_members.selector, members.selector])
        end
      end
  end
end
