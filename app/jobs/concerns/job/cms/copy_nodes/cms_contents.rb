module Job::Cms::CopyNodes::CmsContents
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache

  def copy_cms_content(cache_id, src_content, options = {})
    klass = src_content.class
    dest_content = nil
    dest_content_filename = src_content.filename.gsub(/#{@cur_node.filename}/, @target_node_name)

    id = cache(cache_id, src_content.id) do
      options[:before].call(src_content) if options[:before]
      dest_content = klass.site(@cur_site).where(filename: dest_content_filename).first
      return dest_content.id if dest_content.present?

      # at first, copy non-reference values and references which have no possibility of circular reference
      dest_content = klass.new(cur_site: @cur_site)
      dest_content.attributes = copy_basic_attributes(src_content, klass)
      dest_content.filename = dest_content_filename
      dest_content.save!
      dest_content.id
    end

    if dest_content
      # after create item, copy references which have possibility of circular reference
      dest_content.attributes = resolve_unsafe_references(src_content, klass)
      update_html_strings(src_content, dest_content) if src_content.class.to_s =~ /Part/
      dest_content.keywords = src_content.keywords if src_content.try(:keywords)
      dest_content.save!

      options[:after].call(src_content, dest_content) if options[:after]
    end

    dest_content ||= klass.site(@cur_site).find(id) if id
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
      :part
    elsif ancestors.include?(Cms::Model::Member)
      :member
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

  def update_html_strings(src_content, dest_content)
    from = "/" + src_content.filename.match(/(.*\/).*.part.html/)[1]
    to = "/" + dest_content.filename.match(/(.*\/).*.part.html/)[1]
    [:html, :upper_html, :lower_html, :loop_html].each do |attribute|
      next if dest_content[attribute].nil?
      dest_content[attribute] = src_content[attribute].gsub(from, to)
    end
    dest_content
  end
end
