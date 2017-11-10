class Gws::Chorg::RunParams
  include SS::Document

  field :reservation, type: DateTime

  validate :check_job_mode

  permit_params :reservation

  private

  def check_job_mode
    if reservation.present? && SS.config.job.default['mode'] != 'service'
      errors.add(:base, I18n.t('mongoid.errors.models.chorg/run_params.job_mode_is_not_service'))
    end
  end
end
