module Cms::Addon::Form::Page
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_reader :column_link_errors

    belongs_to :form, class_name: 'Cms::Form'
    embeds_many :column_values, class_name: 'Cms::Column::Value::Base', cascade_callbacks: true, validate: false,
                after_add: :update_column_values_updated, after_remove: :update_column_values_updated,
                extend: Cms::Extensions::ColumnValuesRelation
    field :column_values_updated, type: DateTime

    permit_params :form_id, column_values: [ :_type, :column_id, :order, :alignment, in_wrap: {} ]
    accepts_nested_attributes_for :column_values

    # default validation `validates_associated :column_values` is not suitable for column_values.
    # So, specific validation should be defined.
    validate :validate_column_values
    validate :validate_column_links, on: :link

    before_save :delete_unlinked_files

    after_generate_file :generate_public_files, if: ->{ serve_static_relation_files? } if respond_to?(:after_generate_file)
    after_remove_file :remove_public_files if respond_to?(:after_remove_file)
    after_merge_branch :merge_column_values rescue nil

    liquidize do
      export :column_values, as: :values
    end
  end

  # for creating branch page
  def copy_column_values(from_item)
    self.column_values = from_item.column_values.map do |column_value|
      column_value.new_clone
    end
  end

  private

  def validate_column_values
    column_values.each do |column_value|
      next if column_value.validated?
      next if column_value.valid?

      self.errors.messages[:base] += column_value.errors.map do |attribute, error|
        if %i[value values].include?(attribute.to_sym)
          column_value.name + error
        else
          I18n.t(
            "cms.column_value_error_template", name: column_value.name,
            error: column_value.errors.full_message(attribute, error))
        end
      end
    end
  end

  def validate_column_links
    @column_link_errors = []

    column_values.each do |column_value|
      column_value.valid?(:link)
      if column_value.link_errors.present?
        @column_link_errors += column_value.link_errors
      end
    end
  end

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

  def update_column_values_updated(*_args)
    self.column_values_updated = Time.zone.now
  end

  def column_values_was
    docs = attribute_was("column_values")

    if docs.present?
      docs = docs.map do |doc|
        Mongoid::Factory.build(Cms::Column::Value::Base, doc)
      end
    end

    docs || []
  end

  def delete_unlinked_files
    file_ids_is = []
    self.column_values.each do |column_value|
      file_ids_is += column_value.all_file_ids
    end
    file_ids_is.compact!
    file_ids_is.uniq!

    file_ids_was = []
    column_values_was.each do |column_value|
      file_ids_was += column_value.all_file_ids
    end
    file_ids_was.compact!
    file_ids_was.uniq!

    unlinked_file_ids = file_ids_was - file_ids_is
    unlinked_file_ids.each_slice(20) do |file_ids|
      SS::File.in(id: file_ids).destroy_all
    end
  end
end
