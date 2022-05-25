module Cms::Addon::Column::SelectLike
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    cattr_accessor :use_parent_column_name, instance_accessor: false
    self.use_parent_column_name = false

    field :parent_column_name, type: String
    field :select_options, type: SS::Extensions::Lines, default: ''

    permit_params :parent_column_name, :select_options

    before_validation :normalize_select_options
    validate :validate_select_options
  end

  def parent_column
    return unless self.class.use_parent_column_name
    form.columns.where(name: parent_column_name).first
  end

  private

  def normalize_select_options
    return if select_options.blank?
    self.select_options = select_options.map(&:strip).select(&:present?)
  end

  def validate_select_options
    errors.add(:select_options, :blank) if select_options.blank?
  end
end
