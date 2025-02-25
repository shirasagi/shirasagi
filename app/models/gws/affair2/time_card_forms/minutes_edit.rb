class Gws::Affair2::TimeCardForms::MinutesEdit
  extend SS::Translation
  include ActiveModel::Model
  include SS::PermitParams

  attr_accessor :record, :field
  attr_accessor :minutes

  permit_params :minutes

  validate :numericalize
  validates :minutes, numericality: { only_integer: true, allow_blank: true }

  def initialize(record, field)
    @record = record
    @field = field
    @minutes = record.send(field)
  end

  def numericalize
    self.minutes = minutes.present? ? minutes.to_i : nil
  end

  def save
    return false if invalid?
    @record.send("#{field}=", minutes)
    if !@record.save
      SS::Model.copy_errors(@record, self)
      return false
    end
    true
  end

  private

  class << self
    def t(*args)
      human_attribute_name(*args)
    end
  end
end
