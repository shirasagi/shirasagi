module Cms::Addon::Form::Page
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    belongs_to :form, class_name: 'Cms::Form'
    embeds_many :column_values, class_name: 'Cms::Column::Value::Base', cascade_callbacks: true
    field :column_values_updated, type: DateTime

    permit_params :form_id

    delegate :build_column_values, to: :form

    validate :validate_column_values

    after_generate_file :generate_public_files, if: ->{ serve_static_relation_files? } if respond_to?(:after_generate_file)
    after_remove_file :remove_public_files if respond_to?(:after_remove_file)
    after_merge_branch :merge_column_values rescue nil
  end

  def update_column_values(new_values)
    column_values = self.column_values.to_a.dup

    changes = false
    new_values.each do |new_value|
      old = column_values.find { |column_value| column_value.column_id == new_value.column_id }
      if old.present?
        if old.class == new_value.class
          if old.update_value(new_value)
            changes = true
          end
        else
          column_values.delete_if { |column_value| column_value.column_id == new_value.column_id }
          column_values << new_value
          changes = true
        end
      else
        column_values << new_value
        changes = true
      end
    end

    column_ids = new_values.map(&:column_id)
    column_values = column_values.delete_if do |column_value|
      unincludes = !column_ids.include?(column_value.column_id)
      changes = true if unincludes
      unincludes
    end

    self.column_values = column_values
    # to create history record, timestamp field must be updated
    self.column_values_updated = Time.zone.now if changes
  end

  def validate_column_values
    column_values.each do |column_value|
      column_value.validate_value(self, :column_values)
    end
  end

  def copy_column_values(from_item)
    self.column_values = from_item.column_values.map do |column_value|
      column_value.new_clone
    end
  end

  private

  def generate_public_files
    column_values.each do |column_value|
      column_value.generate_public_files
    end
  end

  def remove_public_files
    column_values.each do |column_value|
      column_value.remove_public_files
    end
  end

  def merge_column_values
    update_column_values(in_branch.column_values.presence || [])
    in_branch.column_values = []
  end
end
