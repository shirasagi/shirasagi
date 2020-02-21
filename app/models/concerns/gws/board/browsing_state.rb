module Gws::Board::BrowsingState
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :browsed_users_hash, type: Hash

    scope :and_read, ->(user) { exists("browsed_users_hash.#{user.id}" => true) }
    scope :and_unread, ->(user) { exists("browsed_users_hash.#{user.id}" => false) }
  end

  def browsed_at(user)
    return if browsed_users_hash.blank?

    browsed_users_hash[user.id.to_s].try(:in_time_zone)
  end

  alias browsed? browsed_at

  def set_browsed!(user)
    # to update hash partially, use `#persist_atomic_operations` method.
    # be careful, you must not use `#set` method. this method update hash totally.
    persist_atomic_operations('$set' => { "browsed_users_hash.#{user.id}" => Time.zone.now.utc })
  end

  def unset_browsed!(user)
    # to update hash partially, use `#persist_atomic_operations` method.
    # be careful, you must not use `#set` method. this method update hash totally.
    persist_atomic_operations('$unset' => { "browsed_users_hash.#{user.id}" => '' })
  end

  def unset_browsed_except!(user)
    save = browsed_users_hash.try { |hash| hash[user.id.to_s] }
    unset(:browsed_users_hash)
    persist_atomic_operations('$set' => { "browsed_users_hash.#{user.id}" => save }) if save
  end

  def browsed_state_options
    %w(unread read).map { |m| [I18n.t("gws/board.options.browsed_state.#{m}"), m] }
  end

  def browsed_user_ids
    browsed = self.browsed_users_hash.to_a.select { |user_id, browsed_at| browsed_at.present? }
    browsed.map { |user_id, browsed_at| user_id }
  end

  def browsed_users
    Gws::User.in(id: browsed_user_ids)
  end
end
