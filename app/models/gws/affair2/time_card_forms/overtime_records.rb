class Gws::Affair2::TimeCardForms::OvertimeRecords
  include ActiveModel::Model
  include SS::PermitParams

  attr_accessor :site, :user, :date
  attr_accessor :records, :in_records, :first_entered_records

  permit_params in_records: [:id,
    :in_start_hour, :in_start_minute, :in_close_hour, :in_close_minute,
    :in_break_start_hour, :in_break_start_minute, :in_break_close_hour, :in_break_close_minute
  ]

  validate :validate_records

  def save
    return false if invalid?

    @first_entered_records = []
    records.each do |record|
      if !record.entered?
        record.entered_at = Time.zone.now
        @first_entered_records << record
      end
      record.save!
    end
  end

  private

  def validate_records
    return if errors.present?
    return if in_records.blank?

    in_records.each do |id, in_record|
      item = records.find { |record| record.id.to_s == id }
      next if item.nil?

      item.attributes = in_record.except("id")
      next if item.valid?

      SS::Model.copy_errors(item, self)
    end
  end

  class << self
    def t(*args)
      human_attribute_name(*args)
    end
  end
end
