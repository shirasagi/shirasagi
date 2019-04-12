module Job::SS::Limit
  extend ActiveSupport::Concern

  included do
    before_enqueue :check_size_limit_per_user!
  end

  module ClassMethods
    def check_size_limit_per_user(user_id)
      return if user_id.blank?
      size = Job::Task.where(user_id: user_id).where(state: 'stop').exists(at: true).count
      size < Job::Service.config.size_limit_per_user
    end

    def check_size_limit_per_user!(user_id)
      raise Job::SizeLimitPerUserExceededError, I18n.t('job.notice.size_limit_exceeded') unless check_size_limit_per_user(user_id)
    end
  end

  private

  def check_size_limit_per_user!
    self.class.check_size_limit_per_user!(user_id)
  end
end
