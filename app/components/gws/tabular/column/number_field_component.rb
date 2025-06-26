class Gws::Tabular::Column::NumberFieldComponent < ApplicationComponent
  include ActiveModel::Model

  strip_trailing_whitespace

  attr_accessor :cur_site, :cur_user, :value, :type, :column, :form, :item, :locale

  delegate :field_type, :min_value, :max_value, :default_value, to: :column
end
