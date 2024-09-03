module Gws::Workflow2::FilePermission
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Permission

  module ClassMethods
    def allow(action, user, opts = {})
      where(allow_condition(action, user, opts))
    end

    def allow_condition(action, user, opts = {})
      user = user.gws_user
      site = opts[:site]
      if user.gws_role_permit_any?(site, "#{action}_other_#{permission_name}")
        # all
        {}
      else
        { user_id: user.id }
      end
    end
  end

  def owned?(user)
    self.user_id == user.id
  end

  def allowed?(action, user, opts = {})
    user    = user.gws_user
    site    = opts[:site] || @cur_site
    return true if user.gws_role_permit_any?(site, "use_gws_workflow2") && owned?(user)
    return true if user.gws_role_permit_any?(site, "#{action}_other_#{self.class.permission_name}")

    errors.add :base, :auth_error if opts.fetch(:adds_error, true)
    false
  end
end
