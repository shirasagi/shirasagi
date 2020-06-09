module Voice::Lockable
  extend ActiveSupport::Concern
  extend SS::Translation

  EPOCH = Time.zone.at(0).utc.freeze

  included do
    field :lock_until, type: DateTime, default: EPOCH
  end

  module ClassMethods
    def acquire_lock(item)
      now = Time.zone.now
      lock_timeout = now + 5.minutes
      criteria = item.class.where(id: item.id)
      criteria = criteria.lt(lock_until: now)
      criteria.find_one_and_update({ '$set' => { lock_until: lock_timeout.utc }}, return_document: :after)
    end

    def release_lock(item)
      criteria = item.class.where(id: item.id)
      criteria = criteria.ne(lock_until: EPOCH)
      criteria.find_one_and_update({ '$set' => { lock_until: EPOCH }}, return_document: :after)
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
