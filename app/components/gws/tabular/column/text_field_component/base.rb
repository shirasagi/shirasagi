module Gws::Tabular::Column::TextFieldComponent::Base
  extend ActiveSupport::Concern

  included do
    strip_trailing_whitespace

    attr_accessor :cur_site, :cur_user, :value, :type, :column, :form, :item, :locale

    delegate :input_type, :max_length, :i18n_default_value, :validation_type, :i18n_state, :html_state, to: :column
  end
end
