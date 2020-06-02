class Chorg::RunParams
  include SS::Document

  field :add_newly_created_group_to_site, type: Integer
  field :forced_overwrite, type: Integer
  field :reservation, type: DateTime

  validate :check_job_mode

  permit_params :add_newly_created_group_to_site, :forced_overwrite, :reservation

  private

  def check_job_mode
    if reservation.present? && SS.config.job.default['mode'] != 'service'
      errors.add(:base, :job_mode_is_not_service)
    end
  end
end
