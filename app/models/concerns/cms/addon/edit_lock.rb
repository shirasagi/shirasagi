module Cms::Addon::EditLock
  extend ActiveSupport::Concern
  extend SS::Addon

  LOCK_INTERVAL = 10.minutes.freeze

  included do
    belongs_to :lock_owner, class_name: "Cms::User"
    field :lock_until, type: DateTime
    validate :validate_lock
    before_destroy :validate_lock
    after_save :release_lock
  end

  def acquire_lock(user: @cur_user, force: false)
    return if user.blank?

    lock_until = LOCK_INTERVAL.from_now
    criteria = self.class.where(id: id)
    unless force
      criteria = criteria.where("$or" => [
        # unlocked
        { lock_owner_id: nil, lock_until: nil },
        # lock by myself
        { lock_owner_id: user.id },
        # lock is expired
        { :lock_until.lt => Time.zone.now },
      ])
    end
    x = criteria.find_one_and_update({ '$set' => { lock_owner_id: user.id, lock_until: lock_until }}, new: true)
    if x
      self.lock_owner_id = x.lock_owner_id
      self.lock_until = x.lock_until
    end
    x.present?
  end

  def release_lock(user: @cur_user, force: false)
    return if user.blank?

    criteria = self.class.where(id: id)
    unless force
      criteria = criteria.where("$or" => [
        # lock by myself
        { lock_owner_id: user.id },
        # lock is expired
        { :lock_until.lt => Time.zone.now }
      ])
    end

    x = criteria.find_one_and_update({ '$unset' => { lock_owner_id: nil, lock_until: nil }}, new: true)
    if x
      remove_attribute(:lock_owner_id) if has_attribute?(:lock_owner_id)
      remove_attribute(:lock_until) if has_attribute?(:lock_until)
    end
    x.present?
  end

  def locked?
    lock_owner_id.present? && lock_until >= Time.zone.now
  end

  def lock_owned?(user = @cur_user)
    return false unless locked?
    return false if user.blank?
    lock_owner_id == user.id
  end

  private
    def validate_lock
      errors.add :base, :locked, user: lock_owner.long_name if locked? && !lock_owned?
      errors.blank?
    end
end
