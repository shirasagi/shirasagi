module Gws::Addon::Share::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    attr_accessor :in_share_max_file_size_mb
    attr_accessor :in_share_files_capacity_mb

    field :share_max_file_size, type: Integer, default: 0
    field :share_files_capacity, type: Integer, default: 0
    field :share_default_sort, type: String, default: 'filename'
    field :share_new_days, type: Integer

    permit_params :share_max_file_size, :in_share_max_file_size_mb
    permit_params :share_files_capacity, :in_share_files_capacity_mb
    permit_params :share_default_sort, :share_new_days

    before_validation :set_share_max_file_size, :set_share_files_capacity

    validates :share_max_file_size, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
    validates :share_files_capacity, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
  end

  def share_default_sort_options
    Gws::Share::File.new.sort_options
  end

  def share_new_days
    self[:share_new_days].presence || 7
  end

  private

  def set_share_max_file_size
    return if in_share_max_file_size_mb.blank?

    self.share_max_file_size = Integer(in_share_max_file_size_mb) * 1_024 * 1_024
  end

  def set_share_files_capacity
    return if in_share_files_capacity_mb.blank?

    self.share_files_capacity = Integer(in_share_files_capacity_mb) * 1_024 * 1_024
  end
end
