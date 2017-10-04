module Gws::Addon::Workflow::ColumnSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :columns, class_name: 'Gws::Workflow::Column', dependent: :destroy, inverse_of: :form
  end
end
