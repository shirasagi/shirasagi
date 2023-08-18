class Gws::Chorg::RunParams
  include SS::Document

  field :reservation, type: DateTime
  field :staff_record_state, type: String
  field :staff_record_name, type: String
  field :staff_record_code, type: String

  validate :check_job_mode
  validates :staff_record_name, presence: true, if: ->{ staff_record_create? }
  validates :staff_record_code, presence: true, if: ->{ staff_record_create? }

  permit_params :reservation
  permit_params :staff_record_state, :staff_record_name, :staff_record_code

  def staff_record_state_options
    %w(create).map do |v|
      [ I18n.t("gws/chorg.options.staff_record_state.#{v}"), v ]
    end
  end

  def staff_record_create?
    staff_record_state == 'create'
  end

  private

  def check_job_mode
    if reservation.present? && SS.config.job.default['mode'] != 'service'
      errors.add(:base, I18n.t('mongoid.errors.models.chorg/run_params.job_mode_is_not_service'))
    end
  end
end
