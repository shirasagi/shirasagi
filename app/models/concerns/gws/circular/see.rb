module Gws::Circular::See
  extend ActiveSupport::Concern

  included do
    field :see_type, type: String, default: 'normal'
    field :seen, type: Hash, default: {}
    permit_params :see_type
  end

  def seen_at(user)
    self.seen[user.id.to_s]
  end

  def seen?(user)
    !unseen?(user)
  end

  def unseen?(user=nil)
    return false if user == nil
    seen.exclude?(user.id.to_s)
  end

  def set_seen(user)
    self.seen[user.id.to_s] = Time.zone.now
    self
  end

  def unset_seen(user)
    self.seen.delete(user.id.to_s)
    self
  end

  def toggle_seen(user)
    seen?(user) ? unset_seen(user) : set_seen(user)
  end

  def see_action_label(u=user)
    key = seen?(u) ? 'unset_seen' : 'set_seen'
    I18n.t(key, scope: 'gws/circular.post')
  end

  def see_type_options
    %w(normal simple).map{ |key| [I18n.t(key, scope: 'gws/circular.options.see_type'), key] }
  end

end
