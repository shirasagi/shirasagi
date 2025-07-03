class Gws::Tabular::Column::DateTimeFieldComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::DateTimeHelper

  strip_trailing_whitespace

  attr_accessor :cur_site, :cur_user, :value, :type, :column, :form, :item, :locale

  delegate :input_type, to: :column
end
