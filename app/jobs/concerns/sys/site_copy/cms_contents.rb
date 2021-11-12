module Sys::SiteCopy::CmsContents
  extend ActiveSupport::Concern
  include SS::Copy::CmsContents

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

  def on_copy(name, field)
    metadata = field.options[:metadata]
    return metadata[:on_copy] if metadata.present?

    if field.association.instance_of?(Mongoid::Association::Referenced::BelongsTo)
      if [Member::Photo, KeyVisual::Image].include?(field.options[:klass])
        if field.association.class_name.constantize.include?(SS::Model::File)
          return :dummy
        end
      end
    end

    nil
  end

  def copy_basic_attributes(content, klass)
    fields = klass.fields
    attributes = content.attributes.map do |field_name, field_value|
      next nil if %w(_id id site_id created updated).include?(field_name)
      next nil unless fields.key?(field_name)

      field_info = fields[field_name]
      unsafe = true
      case on_copy(field_name, field_info)
      when :clear
        next [field_name, field_info.default_val]
      when :value
        next [field_name, field_value]
      when :safe
        unsafe = false
      when :dummy
        next [field_name, field_value]
      end

      ref_class = reference_class(field_name, field_info, content)
      next [field_name, field_value] if ref_class.blank?

      ref_type = reference_type(ref_class)
      next nil if unsafe && unsafe_reference_type?(ref_type)

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

      next nil if [:clear, :value, :safe].include?(on_copy(field_name, fields[field_name]))

      ref_class = reference_class(field_name, fields[field_name], content)
      next nil if ref_class.nil?

      ref_type = reference_type(ref_class)
      next nil if safe_reference_type?(ref_type)

      [field_name, resolve_reference(ref_type, field_value)]
    end

    Hash[attributes.compact]
  end

  def update_html_links(src_content, dest_content, options = {})
    file_url_maps = build_file_url_map(src_content, dest_content)
    dest_field_names = dest_content.class.fields.keys
    names = options[:names].presence || %w(html)
    dest_content.attributes.each do |field_name, field_value|
      next unless names.any? { |name| field_name.include?(name) }
      next unless dest_field_names.include?(field_name)
      next if field_value.blank?

      if field_value.instance_of?(Array)
        file_url_maps.each do |src_url, dest_url|
          field_value = field_value.collect do |value|
            value.gsub(src_url, dest_url)
          end
        end
        field_value = field_value.collect do |value|
          value.gsub(@src_site.full_url, @dest_site.full_url)
        end
      else
        file_url_maps.each do |src_url, dest_url|
          field_value = field_value.gsub(src_url, dest_url)
        end
        field_value = field_value.gsub(@src_site.full_url, @dest_site.full_url)
      end

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

    file_id_map = file_id_map.select do |src_file_id, dest_file_id|
      dest_file_id.present? && dest_file_ids.include?(dest_file_id)
    end

    file_id_map.map do |src_file_id, dest_file_id|
      src_file = SS::File.where(site_id: @src_site.id).find(src_file_id)
      dest_file = SS::File.where(site_id: @dest_site.id).find(dest_file_id)
      [ src_file.url, dest_file.url ]
    end
  end
end
