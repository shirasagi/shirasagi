module SS::UserPermission
  extend ActiveSupport::Concern

  def allowed?(action, user, opts = {})
    return true if new_record?
    user_id == user.id
  end

  module ClassMethods
    def allowed?(action, user, opts = {})
      self.new.allowed?(action, user, opts)
    end

    def allow(action, user, opts = {})
      where(user_id: user.id)
    end
  end
end
