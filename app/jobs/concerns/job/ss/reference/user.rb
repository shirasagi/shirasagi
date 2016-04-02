module Job::SS::Reference::User
  extend ActiveSupport::Concern

  included do
    # user class
    mattr_accessor(:user_class, instance_accessor: false) { SS::User }
    # user
    attr_accessor :user_id
  end

  def user
    return nil if user_id.blank?
    @user ||= self.class.user_class.find(user_id) rescue nil
  end
end
