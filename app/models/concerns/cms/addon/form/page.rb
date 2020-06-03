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

    attr_accessor :link_check_user
    validate :validate_column_links, on: :link

    before_save :cms_form_page_delete_unlinked_files

    around_save :update_file_owner_in_column_values

    if respond_to?(:after_generate_file)
      after_generate_file :cms_form_page_generate_public_files
    end
    after_remove_file :cms_form_page_remove_public_files if respond_to?(:after_remove_file)
    after_merge_branch :cms_form_page_merge_column_values rescue nil

    liquidize do
      export :column_values, as: :values
    end
  end

  # for creating branch page
  def copy_column_values(from_item)
    from_item.column_values.each do |column_value|
      column_value.clone_to(self)
    end
  end

  def render_html(registers = nil)
    return html if form.blank?

    registers ||= {
      cur_site: site,
      cur_path: url,
      cur_page: self
    }

    form.render_html(self, registers).html_safe
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
    @column_link_errors = {}

    column_values.each do |column_value|
      column_value.link_check_user = link_check_user
      column_value.valid?(:link)
      if column_value.link_errors.present?
        @column_link_errors.merge!(column_value.link_errors)
      end
    end
  end

  def cms_form_page_generate_public_files
    column_values.each do |column_value|
      column_value.generate_public_files
    end
  end

  def cms_form_page_remove_public_files
    column_values.each do |column_value|
      column_value.remove_public_files
    end
  end

  def cms_form_page_merge_column_values
    self.column_values = []
    copy_column_values(in_branch)
  end

  def update_column_values_updated(*_args)
    self.column_values_updated = Time.zone.now
  end

  def column_values_was
    return [] if new_record?

    docs = attribute_was("column_values")

    if docs.present?
      docs = docs.map do |doc|
        type = doc["_type"] || doc[:_type]
        effective_kass = type.camelize.constantize rescue Cms::Column::Value::Base
        Mongoid::Factory.build(Cms::Column::Value::Base, doc.slice(*effective_kass.fields.keys.map(&:to_s)))
      end
    end

    docs || []
  end

  def cms_form_page_delete_unlinked_files
    return if new_record?

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
      unlinked_files = SS::File.in(id: file_ids).to_a
      unlinked_files.each do |unlinked_file|
        next if self.id != unlinked_file.owner_item_id

        if [ self, unlinked_file ].all? { |obj| obj.respond_to?(:skip_history_trash) }
          unlinked_file.skip_history_trash = skip_history_trash
        end
        unlinked_file.cur_user = @cur_user
        unlinked_file.destroy
      end
    end
  end

  def update_file_owner_in_column_values
    is_new = new_record?
    yield

    if is_new && form.present?
      file_ids_is = []
      self.column_values.each do |column_value|
        file_ids_is += column_value.all_file_ids
      end
      file_ids_is.compact!
      file_ids_is.uniq!

      SS::File.in(id: file_ids_is).each do |file|
        file.owner_item = self
        file.save
      end
    end
  end
end
