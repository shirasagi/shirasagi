module Gws::Tabular::Column::EnumFieldComponent::Base
  extend ActiveSupport::Concern

  included do
    strip_trailing_whitespace

    attr_accessor :cur_site, :cur_user, :value, :type, :column, :form, :item, :locale

    delegate :select_options, :input_type, to: :column
  end

  def normalized_values
    @normalized_values ||= Array(value).select(&:present?)
  end
end
