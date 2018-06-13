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
      item.disable_thumb = true
      data.each { |k, v| item[k] = v }

      if item.save
        src = SS::File.new(id: id, filename: item.filename)
        @ss_files_map[id] = item.id
        @ss_files_url[src.url] = item.url
        FileUtils.mkdir_p(File.dirname(item.path))
        FileUtils.cp(path, item.path) # FileUtils.mv
      else
        @task.log "[#{item.class}##{item.id}] " + item.errors.full_messages.join(' ')
      end
    end
  end

  def update_ss_files
    @ss_files_map.each do |old_id, id|
      item = SS::File.unscoped.find(id) rescue nil
      next unless item

      item.disable_thumb = true
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
    item.disable_thumb = true
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

    fields = Cms::ApiFilter::Contents::HTML_FIELDS
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
          next if item[field].blank?
          html = item[field].gsub(src_path, dst_path)
          attr[field] = html if item[field] != html
        end
        item.set(attr) if attr.present?
      end
    end
  end
end
