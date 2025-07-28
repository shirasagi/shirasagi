module SS::Lockable
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :lock_until, type: DateTime, default: ::SS::EPOCH_TIME
  end

  module ClassMethods
    def acquire_lock(item, lock_for = nil)
      now = Time.zone.now
      lock_for ||= 5.minutes
      lock_timeout = now + lock_for
      criteria = item.class.where(id: item.id)
      criteria = criteria.lt(lock_until: now.utc)
      criteria.find_one_and_update({ '$set' => { lock_until: lock_timeout.utc }}, return_document: :after)
    end

    def release_lock(item)
      criteria = item.class.where(id: item.id)
      criteria = criteria.ne(lock_until: ::SS::EPOCH_TIME)
      criteria.find_one_and_update({ '$set' => { lock_until: ::SS::EPOCH_TIME }}, return_document: :after)
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
