module SS::Copy::CmsContents
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def array_field?(name, field)
    field.type == Array || field.type.ancestors.include?(Array)
  end

  def reference_class(name, field, content)
    if field.foreign_key? && field.association.polymorphic?
      klass = content[field.association.inverse_type]
      return klass.present? ? klass.constantize : nil
    end

    metadata = field.options[:metadata]
    association = field.association
    return nil if metadata.blank? && association.blank?

    if array_field?(name, field)
      klass = metadata[:elem_class]
    else
      klass = association.try(:class_name)
    end
    klass = klass.constantize if klass.is_a?(String)
    klass
  end

  def reference_type(klass)
    ancestors = klass.ancestors
    if ancestors.include?(SS::Model::Group)
      :group
    elsif ancestors.include?(SS::Model::Site)
      :site
    elsif ancestors.include?(SS::Model::User)
      :user
    elsif ancestors.include?(SS::Model::File)
      :file
    elsif ancestors.include?(Cms::Model::Layout)
      :layout
    elsif ancestors.include?(Cms::Model::Node)
      :node
    elsif ancestors.include?(Cms::Model::Page)
      :page
    elsif ancestors.include?(Cms::Model::Part)
      :part
    elsif ancestors.include?(Cms::Model::Member)
      :member
    elsif klass == Cms::Form
      :form
    elsif ancestors.include?(SS::Model::Column)
      :column
    elsif klass == Cms::LoopSetting
      :loop_setting
    elsif klass == Cms::EditorTemplate
      :editor_template
    elsif klass == Opendata::DatasetGroup
      :opendata_dataset_group
    elsif klass == Opendata::License
      :opendata_license
    elsif ancestors.include?(Jmaxml::QuakeRegion)
      :jmaxml_quake_region
    elsif ancestors.include?(SS::Contact)
      :contact
    else
      raise "unknown reference type: #{klass}"
    end
  end

  def safe_reference_type?(type)
    [:group, :user, :layout].include?(type)
  end

  def unsafe_reference_type?(type)
    !safe_reference_type?(type)
  end

  def copy_basic_attributes(content, klass)
    fields = klass.fields
    attributes = content.attributes.map do |field_name, field_value|
      next nil if %w(_id id site_id created updated).include?(field_name)
      next nil unless fields.key?(field_name)

      ref_class = reference_class(field_name, fields[field_name], content)
      next [field_name, field_value] if ref_class.blank?

      ref_type = reference_type(ref_class)
      next nil if unsafe_reference_type?(ref_type)

      [field_name, resolve_reference(ref_type, field_value)]
    end

    Hash[attributes.compact]
  end

  def resolve_unsafe_references(content, klass = nil, *field_names)
    klass ||= content.class
    fields = klass.fields
    attributes = content.attributes.map do |field_name, field_value|
      next nil if %w(_id id site_id created updated).include?(field_name)
      next nil unless fields.key?(field_name)

      next nil if field_names.present? && !field_names.include?(field_name)
      next [field_name, field_value] if field_value.blank?

      ref_class = reference_class(field_name, fields[field_name], content)
      next nil if ref_class.nil?

      ref_type = reference_type(ref_class)
      next nil if safe_reference_type?(ref_type)

      [field_name, resolve_reference(ref_type, field_value)]
    end

    Hash[attributes.compact]
  end

  def resolve_reference(ref_type, id_or_ids)
    if id_or_ids.respond_to?(:each)
      return id_or_ids.map { |id| resolve_reference(ref_type, id) }
    end

    case ref_type
    when :group
      id_or_ids
    when :site
      id_or_ids
    when :user
      id_or_ids
    when :file
      resolve_file_reference(id_or_ids)
    when :layout
      resolve_layout_reference(id_or_ids)
    when :node
      resolve_node_reference(id_or_ids)
    when :page
      resolve_page_reference(id_or_ids)
    when :part
      resolve_part_reference(id_or_ids)
    when :form
      resolve_form_reference(id_or_ids)
    when :column
      resolve_column_reference(id_or_ids)
    when :loop_setting
      resolve_loop_setting_reference(id_or_ids)
    when :editor_template
      resolve_editor_template_reference(id_or_ids)
    when :opendata_dataset_group
      resolve_opendata_dataset_group_reference(id_or_ids)
    when :opendata_license
      resolve_opendata_license_reference(id_or_ids)
    end
  end
end
