module Sns::Message::MemberPermission
  extend ActiveSupport::Concern

  def allowed?(action, user, opts = {})
    return true if new_record?
    return false if action == :edit && members_type == 'only'
    active_member_ids.include?(user.id)
  end

  module ClassMethods
    def allowed?(action, user, opts = {})
      self.new.allowed?(action, user, opts)
    end

    def allow(action, user, opts = {})
      where(active_member_ids: user.id)
    end
  end
end
