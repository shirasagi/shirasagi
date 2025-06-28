module Inquiry2::Addon::CustomForm2
  extend ActiveSupport::Concern
  extend SS::Addon
  # include Inquiry2::Reference::Form

  included do
    field :column_values_updated, type: DateTime
    embeds_many :column_values, class_name: 'Cms::Column::Value::Base', cascade_callbacks: true, validate: false,
      after_add: :update_column_values_updated, after_remove: :update_column_values_updated,
      extend: Cms::Extensions::ColumnValuesRelation

    permit_params column_values: [ :_type, :column_id, :order, :alignment, in_wrap: {} ]

    accepts_nested_attributes_for :column_values

    validate :validate_column_values
  end

  public

  def validate_column_values
    column_values.each do |column_value|
      next if column_value.validated?
      next if column_value.valid?

      column_value.errors.each do |error|
        attribute = error.attribute
        message = error.message

        if %i[value values].include?(attribute.to_sym)
          new_message = column_value.name + message
        else
          new_message = I18n.t(
            "errors.format2", name: column_value.name,
            error: column_value.errors.full_message(attribute, message))
        end
        self.errors.add :base, new_message
      end
    end
  end

  def skip_required?
    false
  end

  private

  def update_column_values_updated(*_args)
    self.column_values_updated = Time.zone.now
  end
end
