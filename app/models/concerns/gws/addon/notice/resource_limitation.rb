module Gws::Addon::Notice::ResourceLimitation
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :notice_individual_body_size_limit, type: Integer, default: 1_048_576
    field :notice_total_body_size_limit, type: Integer, default: 0
    field :notice_individual_file_size_limit, type: Integer, default: 0
    field :notice_total_file_size_limit, type: Integer, default: 0

    field :notice_total_body_size, type: Integer, default: 0
    field :notice_total_file_size, type: Integer, default: 0

    permit_params :notice_individual_body_size_limit_mb, :notice_total_body_size_limit_mb
    permit_params :notice_individual_file_size_limit_mb, :notice_total_file_size_limit_mb

    validates :notice_individual_body_size_limit,
      numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
    validates :notice_total_body_size_limit,
      numericality: { only_integer: true, greater_than_or_equal_to: 1_024 * 1_024, allow_blank: true }
    validates :notice_individual_file_size_limit,
      numericality: { only_integer: true, greater_than_or_equal_to: 1_024 * 1_024, allow_blank: true }
    validates :notice_total_file_size_limit,
      numericality: { only_integer: true, greater_than_or_equal_to: 1_024 * 1_024, allow_blank: true }
  end

  def notice_individual_body_size_limit_mb
    return if notice_individual_body_size_limit.nil?
    notice_individual_body_size_limit / (1_024 * 1_024)
  end

  def notice_individual_body_size_limit_mb=(value)
    self.notice_individual_body_size_limit = value.nil? ? nil : Integer(value) * 1_024 * 1_024
  end

  def notice_total_body_size_limit_mb
    return if notice_total_body_size_limit.nil?
    notice_total_body_size_limit / (1_024 * 1_024)
  end

  def notice_total_body_size_limit_mb=(value)
    self.notice_total_body_size_limit = value.nil? ? nil : Integer(value) * 1_024 * 1_024
  end

  def notice_individual_file_size_limit_mb
    return if notice_individual_file_size_limit.nil?
    notice_individual_file_size_limit / (1_024 * 1_024)
  end

  def notice_individual_file_size_limit_mb=(value)
    self.notice_individual_file_size_limit = value.nil? ? nil : Integer(value) * 1_024 * 1_024
  end

  def notice_total_file_size_limit_mb
    return if notice_total_file_size_limit.nil?
    notice_total_file_size_limit / (1_024 * 1_024)
  end

  def notice_total_file_size_limit_mb=(value)
    self.notice_total_file_size_limit = value.nil? ? nil : Integer(value) * 1_024 * 1_024
  end

  def notice_total_body_size_over?
    return false if notice_total_body_size_limit <= 0
    notice_total_body_size >= notice_total_body_size_limit
  end

  def notice_total_body_size_percentage
    return 0 if notice_total_body_size_limit <= 0
    percentage = (notice_total_body_size.to_f / notice_total_body_size_limit.to_f) * 100
    percentage = 0 if percentage < 0
    percentage = 100 if percentage > 100
    percentage
  end

  def notice_total_file_size_over?
    return false if notice_total_file_size_limit <= 0
    notice_total_file_size >= notice_total_file_size_limit
  end

  def notice_total_file_size_percentage
    return 0 if notice_total_file_size_limit <= 0
    percentage = (notice_total_file_size.to_f / notice_total_file_size_limit.to_f) * 100
    percentage = 0 if percentage < 0
    percentage = 100 if percentage > 100
    percentage
  end
end
