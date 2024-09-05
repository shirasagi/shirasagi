module Gws::Addon::Share::ResourceLimitation
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :share_max_file_size, type: Integer, default: 0
    field :share_max_folder_size, type: Integer, default: 0
    attr_accessor :in_share_max_file_size_mb
    attr_accessor :in_share_max_folder_size_mb

    permit_params :share_max_file_size, :in_share_max_file_size_mb
    permit_params :share_max_folder_size, :in_share_max_folder_size_mb

    before_validation :set_share_max_file_size
    before_validation :set_share_max_folder_size

    validates :share_max_file_size,
      numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
    validates :share_max_folder_size,
      numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
    validate :validate_share_max_file_size, :validate_share_max_folder_size
  end

  private

  def set_share_max_file_size
    return if in_share_max_file_size_mb.blank?
    self.share_max_file_size = Integer(in_share_max_file_size_mb) * 1_024 * 1_024
  end

  def set_share_max_folder_size
    return if in_share_max_folder_size_mb.blank?
    self.share_max_folder_size = Integer(in_share_max_folder_size_mb) * 1_024 * 1_024
  end

  def validate_share_max_file_size
    file_size = 1024
    return if in_share_max_file_size_mb.to_i <= file_size
    errors.add :share_max_file_size, :less_than_or_equal_to, count: [file_size.to_fs(:delimited), 'MB'].join(' ')
  end

  def validate_share_max_folder_size
    folder_size = 1024**2
    return if in_share_max_folder_size_mb.to_i <= folder_size
    errors.add :share_max_folder_size, :less_than_or_equal_to, count: [folder_size.to_fs(:delimited), 'MB'].join(' ')
  end
end
