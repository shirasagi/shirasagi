#
# Prior to Rails 5.0 release, import some codes from master branch.
# This file removes safely after upgraded Rails 5.0.
#
# Rails 5.0 のリリース前に、master ブランチからコードをインポートします。
# Rails 5.0 へアップグレードした後なら、このファイルは削除しても安全です。
#
class ActiveJob::Base
  class << self
    def deserialize(job_data)
      job = job_data['job_class'].constantize.new
      job.deserialize(job_data)
      job
    end
  end

  def deserialize(job_data)
    self.job_id               = job_data['job_id']
    self.queue_name           = job_data['queue_name']
    self.priority             = job_data['priority'] if self.respond_to?(:priority=)
    self.serialized_arguments = job_data['arguments']
    self.locale               = job_data['locale'] || I18n.locale.to_s
  end
end
