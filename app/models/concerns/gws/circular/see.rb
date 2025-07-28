module Gws::Circular::See
  extend ActiveSupport::Concern

  included do
    field :see_type, type: String, default: 'normal'
    field :seen, type: Hash, default: {}
    permit_params :see_type
  end

  def seen_at(user)
    self.seen[user.id.to_s].try { |time| time.in_time_zone }
  end

  def seen?(user)
    !unseen?(user)
  end

  def unseen?(user = nil)
    return false if user.nil?

    seen.exclude?(user.id.to_s)
  end

  def set_seen!(user)
    persist_atomic_operations('$set' => { "seen.#{user.id}" => Time.zone.now.utc })
  end

  def unset_seen!(user)
    persist_atomic_operations('$unset' => { "seen.#{user.id}" => '' })
  end

  def see_action_label(user)
    key = seen?(user) ? 'unset_seen' : 'set_seen'
    I18n.t(key, scope: 'gws/circular.post')
  end

  def see_type_options
    %w(normal simple).map{ |key| [I18n.t(key, scope: 'gws/circular.options.see_type'), key] }
  end

  def seen_users
    seen = self.seen.to_a.select { |user_id, seen_at| seen_at.present? }
    seen_user_ids = seen.map { |user_id, seen_at| user_id }
    Gws::User.in(id: seen_user_ids)
  end

  def see_type_simple?
    see_type == "simple"
  end

  def see_type_normal?
    !see_type_simple?
  end
end
