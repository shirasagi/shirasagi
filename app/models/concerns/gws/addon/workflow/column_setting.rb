module Gws::Addon::Workflow::ColumnSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :columns, class_name: 'Gws::Column::Base', dependent: :destroy, inverse_of: :form, as: :form
    delegate :build_column_values, to: :columns
  end
end
