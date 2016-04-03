module Job::SS::Binding::User
  extend ActiveSupport::Concern

  included do
    # user class
    mattr_accessor(:user_class, instance_accessor: false) { SS::User }
    # user
    attr_accessor :user_id
  end

  def user
    return nil if user_id.blank?
    @user ||= self.class.user_class.or({ id: user_id }, { uid: user_id }, { email: user_id }).first
  end

  def bind(bindings)
    if bindings['user_id'].present?
      self.user_id = bindings['user_id'].to_param
      @user = nil
    end
    super
  end

  def bindings
    ret = super
    ret.merge!({ 'user_id' => user_id }) if user_id.present?
    ret
  end
end
