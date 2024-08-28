module SS::Model
  class Current < ActiveSupport::CurrentAttributes
    attribute :record_timestamps

    resets { self.record_timestamps = true }

    def initialize
      super
      self.record_timestamps = true
    end
  end

  def self.copy_errors(src, dest, prefix: nil)
    src.errors.full_messages.each do |message|
      message = "#{prefix}#{message}" if prefix
      dest.errors.add :base, message
    end
  end

  def self.container_of(item)
    return unless item
    item.embedded? ? item._parent : item
  end

  def self.record_timestamps?
    SS::Model::Current.record_timestamps
  end

  def self.without_record_timestamps
    save_record_timestamps = SS::Model::Current.record_timestamps
    SS::Model::Current.record_timestamps = false
    yield
  ensure
    SS::Model::Current.record_timestamps = save_record_timestamps
  end
end
