module Sys::SiteCopy::CmsContents
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache

  def copy_cms_content(cache_id, src_content, options = {})
    klass = src_content.class
    dest_content = nil
    id = cache(cache_id, src_content.id) do
      options[:before].call(src_content) if options[:before]
      dest_content = klass.site(@dest_site).where(filename: src_content.filename).first
      return dest_content.id if dest_content.present?

      # at first, copy non-reference values and references which have no possibility of circular reference
      dest_content = klass.new(cur_site: @dest_site)
      dest_content.attributes = copy_basic_attributes(src_content, klass)
      dest_content.save!
      dest_content.id
    end

    if dest_content
      # after create item, copy references which have possibility of circular reference
      dest_content.attributes = resolve_unsafe_references(src_content, klass)
      update_html_links(src_content, dest_content)
      dest_content.save!

      options[:after].call(src_content, dest_content) if options[:after]
    end

    dest_content ||= klass.site(@dest_site).find(id) if id
    dest_content
  end

  def array_field?(name, field)
    field.type == Array || field.type.ancestors.include?(Array)
  end

  def reference_class(name, field)
    metadata = field.metadata
    return nil if metadata.blank?

    if array_field?(name, field)
      klass = metadata[:elem_class]
    else
      klass = metadata.try(:class_name)
    end
    klass = klass.constantize if klass.is_a?(String)
    klass
  end

  def reference_type(klass)
    ancestors = klass.ancestors
    if ancestors.include?(SS::Model::Group)
      :group
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
      part
    else
      raise "unknown reference type: #{klass}"
    end
  end

  def safe_reference_type?(type)
    [:group, :user, :file, :layout].include?(type)
  end

  def unsafe_reference_type?(type)
    !safe_reference_type?(type)
  end

  def copy_basic_attributes(content, klass)
    fields = klass.fields
    attributes = content.attributes.map do |field_name, field_value|
      next nil if %w(_id id site_id created updated).include?(field_name)
      next nil unless fields.key?(field_name)

      ref_class = reference_class(field_name, fields[field_name])
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

      ref_class = reference_class(field_name, fields[field_name])
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
    end
  end

  def update_html_links(src_content, dest_content)
    file_url_maps = build_file_url_map(src_content, dest_content)
    dest_field_names = dest_content.class.fields.keys
    dest_content.attributes.each do |field_name, field_value|
      next unless field_name.include?('html')
      next unless dest_field_names.include?(field_name)
      next if field_value.blank?

      file_url_maps.each do |src_url, dest_url|
        field_value = field_value.gsub(src_url, dest_url)
      end

      field_value = field_value.gsub(@src_site.full_url, @dest_site.full_url)
      dest_content[field_name] = field_value
    end
  end

  def build_file_url_map(src_content, dest_content)
    src_file_ids = src_content.try(:file_ids).try(:to_a)
    return [] if src_file_ids.blank?
    dest_file_ids = dest_content.try(:file_ids).try(:to_a)
    return [] if dest_file_ids.blank?

    file_id_map = src_file_ids.map do |src_file_id|
      [ src_file_id, cache(:files, src_file_id) ]
    end

    file_id_map = file_id_map.select { |src_file_id, dest_file_id| dest_file_id.present? && dest_file_ids.include?(dest_file_id) }
    file_id_map.map do |src_file_id, dest_file_id|
      src_file = SS::File.where(site_id: @src_site.id).find(src_file_id)
      dest_file = SS::File.where(site_id: @dest_site.id).find(dest_file_id)
      [ src_file.url, dest_file.url ]
    end
  end
end
