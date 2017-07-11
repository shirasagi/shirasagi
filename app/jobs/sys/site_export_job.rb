class Sys::SiteExportJob < SS::ApplicationJob
  include Job::SS::TaskFilter

  def perform
    @src_site = Cms::Site.find(@task.source_site_id)

    @output_dir = "#{Rails.root}/private/export/site-#{@src_site.host}"
    @output_zip = "#{@output_dir}.zip"

    FileUtils.rm_rf(@output_dir)
    FileUtils.mkdir_p(@output_dir)

    @task.log("=== Site Export ===")
    @task.log("Site name: #{@src_site.name}")
    @task.log("Temporary directory: #{@output_dir}")
    @task.log("Outout file: #{@output_zip}")

    @ss_file_ids = []

    invoke :export_version
    invoke :export_cms_site
    invoke :export_cms_groups
    invoke :export_cms_users
    invoke :export_cms_roles
    invoke :export_cms_layouts
    invoke :export_cms_body_layouts
    invoke :export_cms_nodes
    invoke :export_cms_parts
    invoke :export_cms_pages
    invoke :export_cms_page_searches
    invoke :export_cms_notices
    invoke :export_cms_editor_templates
    invoke :export_cms_theme_templates
    invoke :export_cms_source_cleaner_templates
    invoke :export_ezine_columns
    invoke :export_inquiry_columns
    invoke :export_kana_dictionaries
    invoke :export_opendata_dataset_groups
    invoke :export_opendata_licenses

    # files
    invoke :export_cms_files
    invoke :export_ss_files

    # compress
    invoke :compress

    FileUtils.rm_rf(@output_dir)
    @task.log("Completed.")
  end

  private

  def compress
    FileUtils.rm(@output_zip) if File.exist?(@output_zip)

    zip = Sys::SiteExport::Zip.new(@output_zip)
    zip.output_dir = @output_dir
    zip.site_dir = @src_site.path
    zip.compress
  end

  def invoke(method)
    @task.log("- " + method.to_s.sub('_', ' '))
    send(method)
  end

  def write_json(name, data)
    File.write("#{@output_dir}/#{name}.json", data)
  end

  def open_json(name)
    Sys::SiteExport::Json.new("#{@output_dir}/#{name}.json")
  end

  def export_documents(name, model, scope = nil, &block)
    json = open_json(name)
    scope ||= model.site(@src_site)
    scope.pluck(:id).each do |id|
      item = model.unscoped.find(id)
      yield(item) if block_given?
      json.write(item.to_json)
      store_file_ids(item)
    end
    json.close
  end

  def store_file_ids(item)
    @ss_file_ids += item[:file_ids] if item[:file_ids].present?
    @ss_file_ids << item[:thumb_id] if item[:thumb_id].present?
    @ss_file_ids << item[:image_id] if item[:image_id].present?
    @ss_file_ids << item[:file_id] if item[:file_id].present?
    @ss_file_ids << item[:tsv_id] if item[:tsv_id].present?
    @ss_file_ids << item[:icon_id] if item[:icon_id].present?
  end

  def export_version
    write_json "version", SS.version.to_json
  end

  def export_cms_site
    write_json "cms_site", @src_site.to_json
  end

  def export_cms_groups
    items = @src_site.groups.only(:id, :name).entries
    @src_site.groups.each do |g|
      items += g.descendants.only(:id, :name).entries
    end
    write_json "cms_groups", items.to_json
  end

  def export_cms_users
    json = open_json("cms_users")
    Cms::User.unscoped.site(@src_site, state: 'all').pluck(:id).each do |id|
      json.write Cms::User.unscoped.only(:uid, :email, :cms_role_ids).find(id).to_json
    end
    json.close
  end

  def export_cms_roles
    json = open_json("cms_roles")
    Cms::Role.site(@src_site).pluck(:id).each do |id|
      json.write Cms::Role.unscoped.without(:created, :updated).find(id).to_json
    end
    json.close
  end

  def export_cms_layouts
    export_documents "cms_layouts", Cms::Layout
  end

  def export_cms_body_layouts
    export_documents "cms_body_layouts", Cms::BodyLayout
  end

  def export_cms_nodes
    export_documents "cms_nodes", Cms::Node
  end

  def export_cms_parts
    export_documents "cms_parts", Cms::Part
  end

  def export_cms_pages
    export_documents "cms_pages", Cms::Page do |item|
      # opendata
      @ss_file_ids += item[:resources].map { |m| m[:file_id] } if item[:resources].present?
      @ss_file_ids += item[:url_resources].map { |m| m[:file_id] } if item[:url_resources].present?
      @ss_file_ids += item[:appfiles].map { |m| m[:file_id] } if item[:appfiles].present?
    end
  end

  def export_cms_notices
    export_documents "cms_notices", Cms::Notice
  end

  def export_cms_editor_templates
    export_documents "cms_editor_templates", Cms::EditorTemplate
  end

  def export_cms_theme_templates
    export_documents "cms_theme_templates", Cms::ThemeTemplate
  end

  def export_cms_source_cleaner_templates
    export_documents "cms_source_cleaner_templates", Cms::SourceCleanerTemplate
  end

  def export_cms_page_searches
    export_documents "cms_page_searches", Cms::PageSearch
  end

  def export_ezine_columns
    export_documents "ezine_columns", Ezine::Column
  end

  def export_inquiry_columns
    export_documents "inquiry_columns", Inquiry::Column
  end

  def export_kana_dictionaries
    export_documents "kana_dictionaries", Kana::Dictionary
  end

  def export_opendata_dataset_groups
    export_documents "opendata_dataset_groups", Opendata::DatasetGroup
  end

  def export_opendata_licenses
    export_documents "opendata_licenses", Opendata::License
  end

  def export_cms_files
    @ss_file_ids += Cms::File.site(@src_site).where(model: "cms/file").pluck(:id)
  end

  def export_ss_files
    FileUtils.mkdir_p("#{@output_dir}/files")

    json = open_json("ss_files")
    @ss_file_ids.compact.sort.each do |id|
      item = SS::File.unscoped.find(id) rescue nil
      next unless item

      item[:export_path] = copy_file(item)
      json.write(item.to_json)

      item.thumbs.each do |thumb|
        thumb[:export_path] = copy_file(thumb)
        json.write(thumb.to_json)
      end
    end
    json.close
  end

  def copy_file(item)
    return nil unless File.exist?(item.path)
    file = item.path.sub(/.*\/(files\/)/, '\\1')
    path = "#{@output_dir}/#{file}"
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.cp(item.path, path)
    file
  end
end
