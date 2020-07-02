module SS::Lockable
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :lock_until, type: DateTime, default: ::Time::EPOCH
  end

  module ClassMethods
    def acquire_lock(item, lock_for = nil)
      now = Time.zone.now
      lock_for ||= 5.minutes
      lock_timeout = now + lock_for
      criteria = item.class.where(id: item.id)
      criteria = criteria.lt(lock_until: now)
      criteria.find_one_and_update({ '$set' => { lock_until: lock_timeout.utc }}, return_document: :after)
    end

    def release_lock(item)
      criteria = item.class.where(id: item.id)
      criteria = criteria.ne(lock_until: ::Time::EPOCH)
      criteria.find_one_and_update({ '$set' => { lock_until: ::Time::EPOCH }}, return_document: :after)
    end

    def ensure_release_lock(item)
      begin
        ret = yield
      ensure
        release_lock item
      end
      ret
    end
  end
end
