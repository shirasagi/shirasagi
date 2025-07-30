module Sys::SiteImport::File
  extend ActiveSupport::Concern

  def import_ss_files
    @ss_files_map = {}

    read_json("ss_files").each do |data|
      id   = data.delete('_id')
      path = "#{@import_dir}/#{data.delete('export_path')}"
      next unless File.file?(path)

      data = convert_data(data)
      data['original_id'] = @ss_files_map[data['original_id']] if data.key?('original_id')

      item = SS::File.unscoped.where(data.reject { |k, v| v.blank? }).first || dummy_ss_file(data)
      item.record_timestamps = false
      item.in_disable_variant_processing = true
      data.each do |k, v|
        next if %w(owner_item_type owner_item_id).include?(k)
        item[k] = v
      end

      if item.save
        src = SS::File.new(id: id, name: data["name"], filename: data["filename"])
        src = src.becomes_with_model

        @ss_files_map[id] = item.id
        @ss_files_url[src.url] = item.url
        FileUtils.mkdir_p(File.dirname(item.path))
        FileUtils.cp(path, item.path) # FileUtils.mv

        if Fs.to_io(path) { |io| SS::ImageConverter.image?(io) }
          @ss_files_url[src.thumb_url] = item.thumb_url
          item.in_disable_variant_processing = false
          item.update_variants
        end
      else
        @task.log "[#{item.class}##{item.id}] " + item.errors.full_messages.join(' ')
      end
    end
  end

  def update_ss_files
    @ss_files_map.each do |old_id, id|
      item = SS::File.unscoped.find(id) rescue nil
      next unless item

      item.in_disable_variant_processing = true
      item[:node_id] = @cms_nodes_map[item[:node_id]] if item[:node_id].present?
      save_document(item)
    end
  end

  def dummy_ss_file(data)
    file = Fs::UploadedFile.new("ss_export")
    file.original_filename = 'dummy'

    item = SS::File.new(model: 'ss/dummy')
    item.created = data['created']
    item.updated = data['updated']
    item.in_disable_variant_processing = true
    item.in_file = file
    item.save
    item.in_file = nil
    item
  end

  def update_ss_files_url
    @ss_files_url.each do |src, dst|
      replace_html_with_url(src, dst)
    end
  end

  def replace_html_with_url(src, dst)
    src_path = "=\"#{src}"
    dst_path = "=\"#{dst}"

    # html fields
    fields = Cms::ApiFilter::Contents::HTML_FIELDS + Cms::ApiFilter::Contents::CONTACT_FIELDS
    path = "=\"#{::Regexp.escape(src)}"
    cond = { "$or" => fields.map { |field| { field => /#{path}/ } } }

    criterias = [
      Cms::Page.in(id: @cms_pages_map.values),
      Cms::Part.in(id: @cms_parts_map.values),
      Cms::Layout.in(id: @cms_layouts_map.values)
    ]
    criterias.each do |items|
      items.where(cond).each do |item|
        attr = {}
        fields.each do |field|
          html = replace_html_with_url(item[field])
          attr[field] = html if html != item[field]
        end
        item.set(attr) if attr.present?
      end
    end

    # column_values
    criteria = Cms::Page.in(id: @cms_pages_map.values)
    criteria = criteria.where(column_values: { "$exists" => true, "$ne" => [] })
    criteria.each do |item|
      next if !item.respond_to?(:column_values)
      next if item.column_values.blank?

      item.column_values.each do |column_value|
        next if !column_value.respond_to?(:value)
        next if column_value.value.blank?

        value = column_value.value
        new_value = value.gsub(src_path, dst_path)
        column_value.set(value: new_value) if new_value != value
      end
    end
  end
end
