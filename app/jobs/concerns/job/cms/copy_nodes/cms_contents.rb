module Job::Cms::CopyNodes::CmsContents
  extend ActiveSupport::Concern
  include SS::Copy::CmsContents

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

  def safe_reference_type?(type)
    [:group, :user, :file, :layout].include?(type)
  end

  def update_html_strings(src_content, dest_content)
    from = "/" + src_content.filename.match(/(.*\/).*.part.html/)[1]
    to = "/" + dest_content.filename.match(/(.*\/).*.part.html/)[1]
    [:html, :upper_html, :lower_html, :loop_html, :loop_liquid].each do |attribute|
      next if dest_content[attribute].nil?
      dest_content[attribute] = src_content[attribute].gsub(from, to)
    end
    dest_content
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
      else
        file_url_maps.each do |src_url, dest_url|
          field_value = field_value.gsub(src_url, dest_url)
        end
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
      src_file = SS::File.where(site_id: @cur_site.id).find(src_file_id)
      dest_file = SS::File.where(site_id: @cur_site.id).find(dest_file_id)
      [ src_file.url, dest_file.url ]
    end
  end
end
