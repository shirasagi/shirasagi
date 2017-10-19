module Gws::Addon::Facility::ColumnSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :columns, class_name: 'Gws::Column::Base', dependent: :destroy, inverse_of: :form, as: :form
    delegate :build_custom_values, to: :columns
    delegate :to_validator, to: :columns
  end
end
