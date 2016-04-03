module Job::SS::Core
  extend ActiveSupport::Concern

  module ClassMethods
    def bind(bindings)
      ::Job::BindedJob.new(self, {}, bindings)
    end

    def set(options)
      ::Job::BindedJob.new(self, options, {})
    end
  end

  def bind(bindings)
    self
  end

  def bindings
    {}
  end

  def serialize
    super.merge('serialized_bindings' => serialize_bindings)
  end

  def deserialize(job_data)
    super
    deserialize_bindings(job_data)
  end

  private

  def serialize_bindings
    ActiveJob::Arguments.serialize([ bindings ])
  end

  def deserialize_bindings(job_data)
    bindings = job_data['serialized_bindings']
    if bindings.present?
      bindings = ActiveJob::Arguments.deserialize(bindings)
      bindings = bindings.first
      bind(bindings)
    end
  end
end
