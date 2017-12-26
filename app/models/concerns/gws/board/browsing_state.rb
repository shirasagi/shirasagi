module Gws::Board::BrowsingState
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :browsed_users_hash, type: Hash
  end

  def browsed_at(user)
    return if browsed_users_hash.blank?
    browsed_users_hash[user.id.to_s].try(:in_time_zone)
  end
  alias browsed? browsed_at

  def set_browsed(user)
    hash = self.browsed_users_hash
    hash ||= {}
    hash = hash.dup
    hash[user.id.to_s] = Time.zone.now

    self.browsed_users_hash = hash
  end

  def browsed_state_options
    %w(unread read).map { |m| [I18n.t("gws/board.options.browsed_state.#{m}"), m] }
  end

  def browsed_users
    browsed = self.browsed_users_hash.to_a.select { |user_id, browsed_at| browsed_at.present? }
    browsed_user_ids = browsed.map { |user_id, browsed_at| user_id }
    Gws::User.in(id: browsed_user_ids)
  end
end
