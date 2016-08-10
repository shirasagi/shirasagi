module Job::Cms::CopyNodes::CmsContents
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache
  include Sys::SiteCopy::CmsContents

  def copy_cms_content(cache_id, src_content, options = {})
    klass = src_content.class
    dest_content = nil
    dest_content_filename = src_content.filename.gsub(/^#{@base_node_name}/, @target_node_name)
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
      update_html_links(src_content, dest_content)  # TODO: あとで実装しなおす
      dest_content.save!

      options[:after].call(src_content, dest_content) if options[:after]
    end

    dest_content ||= klass.site(@cur_site).find(id) if id
    dest_content
  end
end
