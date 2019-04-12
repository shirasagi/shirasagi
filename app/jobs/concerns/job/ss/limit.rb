module Job::SS::Limit
  extend ActiveSupport::Concern

  included do
    delegate :check_size_limit_per_user!, to: self
    before_enqueue -> { check_size_limit_per_user!(user_id) }
  end

  module ClassMethods
    def check_size_limit_per_user?(user_id)
      return true if user_id.blank?
      size = Job::Task.where(user_id: user_id).and("$or" => [{ at: { '$exists' => true } }, { state: /ready|running/ }]).count
      size < Job::Service.config.size_limit_per_user
    end

    def check_size_limit_per_user!(user_id)
      raise Job::SizeLimitPerUserExceededError, I18n.t('job.notice.size_limit_exceeded') unless check_size_limit_per_user?(user_id)
    end
  end
end
