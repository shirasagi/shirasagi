module Gws::GroupPermission
  extend ActiveSupport::Concern
  include SS::Permission

  included do
    field :permission_level, type: Integer, default: 1
    embeds_ids :groups, class_name: "SS::Group"
    permit_params :permission_level, group_ids: []
  end

  public
    def owned?(user)
      (self.group_ids & user.group_ids).present?
    end

    def permission_level_options
      [%w(1 1), %w(2 2), %w(3 3)]
    end

    # @param [String] action
    # @param [Gws::User] user
    # @param [SS::Group] group
    def allowed?(action, user, opts = {})
      if self.new_record?
        access = :other
        permit_level = 1
      else
        # TODO: given group from args[2]
        access = owned?(user) ? :private : :other
        permit_level = self.permission_level
      end

      action = permission_action || action

      permits = []
      permits << "#{action}_#{access}_#{self.class.permission_name}"
      permits << "#{action}_other_#{self.class.permission_name}" if access == :private

      permits.each do |permit|
        return true if user.gws_role_permissions[permit].to_i > 0
      end
      false
    end

  module ClassMethods
    public
      # @param [String] action
      # @param [Gws::User] user
      # @param [SS::Group] group
      def allow(action, user)
        action = permission_action || action
        permit = "#{action}_other_#{permission_name}"

        level = user.gws_roles.in(permissions: permit).pluck(:permission_level).max
        return where("$or" =>  [{permission_level: {"$lte" => level }}, {permission_level:  nil}]) if level

        permit = "#{action}_private_#{permission_name}"
        level = user.gws_roles.in(permissions: permit).pluck(:permission_level).max
        return self.in(group_ids: user.group_ids).where(permission_level: {"$lte" => level }) if level

        where({ _id: -1 })
      end
  end
end
