module Gws::Addon::Workflow2::CustomForm
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :cur_form, :in_custom_form_dummy, :skip_validate_column_values

    belongs_to :form, class_name: 'Gws::Workflow2::Form::Base'
    embeds_many :column_values, class_name: 'Gws::Column::Value::Base', cascade_callbacks: true

    permit_params :in_custom_form_dummy

    before_validation :set_form_id, if: ->{ @cur_form }
    validate :validate_column_values

    around_save :update_file_owner_in_column_values

    scope :form, ->(form) { where(form_id: form.id) }
  end

  def cur_form
    @cur_form ||= self.form
  end

  def read_column_value(column)
    return if column_values.blank?

    column_id = column.respond_to?(:id) ? column.id.to_s : column.to_s
    val = column_values.where(column_id: column_id).first
    return if val.blank?

    val
  end

  def remove_column_value(column)
    return if column_values.blank?

    column_id = column.respond_to?(:id) ? column.id.to_s : column.to_s
    self.column_values.where(column_id: column_id).destroy_all
  end

  def update_column_values(new_values)
    column_values = self.column_values.to_a.dup

    new_values.each do |new_value|
      old = column_values.find { |column_value| column_value.column_id == new_value.column_id }
      if old.present?
        if old.instance_of?(new_value.class)
          old.update_value(new_value)
        else
          column_values.delete_if { |column_value| column_value.column_id == new_value.column_id }
          column_values << new_value
        end
      else
        column_values << new_value
      end
    end

    column_ids = new_values.map(&:column_id)
    column_values = column_values.delete_if do |column_value|
      !column_ids.include?(column_value.column_id)
    end

    self.column_values = column_values
  end

  private

  def set_form_id
    return unless @cur_form
    self.form_id = @cur_form.id
  end

  def validate_column_values
    return if skip_validate_column_values
    return if form.blank?
    column_values.each do |column_value|
      column_value.validate_value(self, :column_values)
    end
  end

  def update_file_owner_in_column_values
    is_new = new_record?
    yield

    if is_new && form.present?
      column_values.each do |column_value|
        column_value.update_file_owner(self)
      end
    end
  end
end
