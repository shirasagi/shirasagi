module Job::SS::Binding::User
  extend ActiveSupport::Concern

  included do
    # user class
    mattr_accessor(:user_class, instance_accessor: false) { SS::User }
    # user
    attr_accessor :user_id, :user_password
  end

  def user
    return nil if user_id.blank?
    @user ||= begin
      user = self.class.user_class.where("$or" => [{ id: user_id }, { uid: user_id }, { email: user_id }]).first
      user.decrypted_password = SS::Crypto.decrypt(self.user_password) if user && self.user_password
      user
    end
  end

  def bind(bindings)
    if bindings['user_id'].present?
      self.user_id = bindings['user_id'].to_param
      self.user_password = bindings['user_password'].to_s.presence
      @user = nil
    end
    super
  end

  def bindings
    ret = super
    ret['user_id'] = user_id if user_id.present?
    ret['user_password'] = user_password if user_password.present?
    ret
  end
end
