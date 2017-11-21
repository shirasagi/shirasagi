module Cms::Addon::Form::Page
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    belongs_to :form, class_name: 'Cms::Form'
    embeds_many :column_values, class_name: 'Cms::Column::Value::Base', cascade_callbacks: true

    permit_params :form_id

    delegate :build_column_values, to: :form

    validate :validate_column_values

    after_merge_branch :merge_column_values rescue nil
  end

  def update_column_values(new_values)
    column_values = self.column_values.to_a.dup

    new_values.each do |new_value|
      old = column_values.find { |column_value| column_value.column_id == new_value.column_id }
      if old.present?
        if old.class == new_value.class
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

  def validate_column_values
    column_values.each do |column_value|
      column_value.validate_value(self, :column_values)
    end
  end

  private

  def merge_column_values
    update_column_values(in_branch.column_values.presence || [])
    in_branch.column_values = []
  end
end
