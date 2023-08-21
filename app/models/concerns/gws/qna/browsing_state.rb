module Gws::Qna::BrowsingState
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :browsed_users_hash, type: Hash
  end

  def browsed_at(user)
    return if browsed_users_hash.blank?
    browsed_users_hash[user.id.to_s].try(:localtime)
  end
  alias browsed? browsed_at

  def set_browsed!(user)
    # to update hash partially, use `#persist_atomic_operations` method.
    # be careful, you must not use `#set` method. this method update hash totally.
    persist_atomic_operations('$set' => { "browsed_users_hash.#{user.id}" => Time.zone.now.utc })
  end
end
