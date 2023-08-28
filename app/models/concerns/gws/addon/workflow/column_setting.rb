module Gws::Addon::Workflow::ColumnSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :columns, class_name: 'Gws::Column::Base', dependent: :destroy, inverse_of: :form, as: :form
    delegate :build_column_values, to: :columns

    before_destroy -> { @destroy_parent = true }
  end

  module ClassMethods
    def update_forms
      @_update_forms
    end

    def update_form(&block)
      @_update_forms ||= []
      @_update_forms << block if block
    end
  end
end
