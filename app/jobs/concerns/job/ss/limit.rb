module Job::SS::Limit
  extend ActiveSupport::Concern

  included do
    before_enqueue :check_size_limit_per_user
  end

  private

  def check_size_limit_per_user
    return if user_id.blank?
    size = Job::Task.where(user_id: user_id).where(state: 'stop').exists(at: true).count
    raise Job::SizeLimitExceededError, I18n.t('job.notice.size_limit_exceeded') if size >= Job::Service.config.size_limit_per_user
  end
end
