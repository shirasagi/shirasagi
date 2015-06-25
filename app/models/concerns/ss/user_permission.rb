module SS::UserPermission
  extend ActiveSupport::Concern

  public
    def allowed?(action, user, opts = {})
      user_id == user.id
    end

  module ClassMethods
    public
      def allow(action, user, opts = {})
        where(user_id: user.id)
      end
  end
end
