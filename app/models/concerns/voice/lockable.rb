module Voice::Lockable
  extend ActiveSupport::Concern

  EPOCH = Time.at(0)

  included do
    field :lock_until, type: DateTime, default: EPOCH
  end

  module ClassMethods
    def acquire_lock(item)
      criteria = item.class.where(id: item.id)
      criteria = criteria.lt(lock_until: Time.now)
      criteria.find_and_modify({ '$set' => { lock_until: 5.minutes.from_now }}, new: true)
    end

    def release_lock(item)
      criteria = item.class.where(id: item.id)
      criteria = criteria.ne(lock_until: EPOCH)
      criteria.find_and_modify({ '$set' => { lock_until: EPOCH }}, new: true)
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
