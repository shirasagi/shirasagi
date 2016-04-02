module Job::SS::Core
  extend ActiveSupport::Concern

  module ClassMethods
    def bind(bindings={})
      ::SS::BindedJob.new(self, bindings)
    end
  end

  def bind(bindings)
    self.site_id = bindings['site_id'].to_param
    self.group_id = bindings['group_id'].to_param
    self.user_id = bindings['user_id'].to_param
    self
  end

  def serialize
    super.merge('bindings' => serialize_bindings)
  end

  def deserialize(job_data)
    super
    deserialize_bindings(job_data)
  end

  def deserialize_bindings(job_data)
    bindings = job_data['bindings']
    if bindings.present?
      bindings = ActiveJob::Arguments.deserialize(bindings)
      bindings = bindings.first
      bind(bindings)
    end
  end

  private

  def serialize_bindings
    bindings = []
    bindings << [ 'site_id', site_id ] if site_id.present?
    bindings << [ 'group_id', group_id ] if group_id.present?
    bindings << [ 'user_id', user_id ] if user_id.present?
    bindings = Hash[bindings]
    bindings = [ bindings ]
    ActiveJob::Arguments.serialize(bindings)
  end
end
