module Gws::Addon::Column::SelectLike
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :select_options, type: SS::Extensions::Lines, default: ''

    permit_params :select_options

    before_validation :normalize_select_options
    validate :validate_select_options
  end

  module ClassMethods
    def default_attributes
      attributes = super
      attributes[:select_options] = SS::Extensions::Lines.demongoize(I18n.t("gws/column.default_select_options"))
      attributes
    end
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
