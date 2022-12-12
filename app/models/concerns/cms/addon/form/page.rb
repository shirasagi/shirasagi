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
    field :form_contains_urls, type: Array, default: []

    permit_params :form_id, column_values: [ :_type, :column_id, :order, :alignment, in_wrap: {} ]
    accepts_nested_attributes_for :column_values

    # default validation `validates_associated :column_values` is not suitable for column_values.
    # So, specific validation should be defined.
    validate :validate_column_values

    attr_accessor :link_check_user

    validate :validate_column_links, on: :link

    before_validation :set_form_contains_urls

    around_save :cms_form_page_around_save_delegate
    around_create :cms_form_page_around_create_delegate
    around_update :cms_form_page_around_update_delegate
    around_destroy :cms_form_page_around_destroy_delegate

    before_save :cms_form_page_delete_unlinked_files

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
  def copy_column_values(from_item, opts = {})
    from_item.column_values.each do |column_value|
      column_value.clone_to(self, opts)
    end
  end

  def render_html(registers = nil)
    return html if form.blank?
    return nil if site.blank?

    registers ||= {
      cur_site: site,
      cur_path: url,
      cur_page: self
    }

    form.render_html(self, registers).html_safe
  end

  def form_files
    files = []
    column_values.each do |value|
      if value.respond_to?(:file_id) && value.file
        files << value.file
      end
      if value.respond_to?(:files) && value.files.present?
        files += value.files.to_a
      end
    end
    files
  end

  def html_bytesize
    render_html.to_s.bytesize
  end

  private

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
    copy_column_values(in_branch, merge_values: true)
  end

  def update_column_values_updated(*_args)
    self.column_values_updated = Time.zone.now
  end

  def column_values_was
    return [] if new_record?

    docs = attribute_was("column_values")

    if docs.present?
      docs = docs.select(&:present?).map do |doc|
        type = doc["_type"] || doc[:_type]
        effective_klass = type.camelize.constantize rescue Cms::Column::Value::Base
        Mongoid::Factory.build(Cms::Column::Value::Base, doc.slice(*effective_klass.fields.keys.map(&:to_s)))
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
    Cms::Reference::Files::Utils.delete_files(self, unlinked_file_ids)
  end

  def set_form_contains_urls
    form_contains_urls = []

    column_values.select{ |c| c[:_type] == 'Cms::Column::Value::Free' }.each do |column_value|
      form_contains_urls << column_value.contains_urls
    end

    column_values.select{ |c| c[:_type] == 'Cms::Column::Value::UrlField' }.each do |column_value|
      form_contains_urls << column_value.link
    end

    column_values.select{ |c| c[:_type] == 'Cms::Column::Value::UrlField2' }.each do |column_value|
      form_contains_urls << column_value.link_url
    end

    column_values.select{ |c| c[:_type] == 'Cms::Column::Value::FileUpload' }.each do |column_value|
      if column_value.link_url.present?
        form_contains_urls << column_value.link_url
      end
    end

    self.form_contains_urls = form_contains_urls.flatten.uniq.compact.collect(&:strip)
  end

  def _delegate_callback_to_column_values(kind, &block)
    invoke_sequence = nil
    invoke_sequence = proc do |index, &block|
      column_value = column_values[index]
      if column_value
        column_value.run_callbacks(kind) do
          invoke_sequence.call(index + 1, &block)
        end
      elsif block_given?
        yield
      end
    end

    invoke_sequence.call(0, &block)
  end

  def cms_form_page_around_save_delegate(&block)
    _delegate_callback_to_column_values(:parent_save, &block)
  end

  def cms_form_page_around_create_delegate(&block)
    _delegate_callback_to_column_values(:parent_create, &block)
  end

  def cms_form_page_around_update_delegate(&block)
    _delegate_callback_to_column_values(:parent_update, &block)
  end

  def cms_form_page_around_destroy_delegate(&block)
    _delegate_callback_to_column_values(:parent_destroy, &block)
  end
end
