class Cms::ContentExportJob < Sys::SiteExportJob

  self.task_name = 'cms:export_content'

  def perform(opts = {})
    @src_site = Cms::Site.find(@task.site_id)

    @output_dir = "#{Rails.root}/private/export/content-#{@src_site.host}"
    @output_zip = "#{@output_dir}.zip"

    FileUtils.rm_rf(@output_dir)
    FileUtils.mkdir_p(@output_dir)

    @task.log("=== Content Export ===")
    @task.log("Site name: #{@src_site.name}")
    @task.log("Temporary directory: #{@output_dir}")
    @task.log("Outout file: #{@output_zip}")

    @ss_file_ids = []

    invoke :export_version
    invoke :export_cms_site
    invoke :export_cms_groups
    invoke :export_cms_users
    invoke :export_cms_forms
    invoke :export_cms_columns
    invoke :export_cms_layouts
    invoke :export_cms_body_layouts
    invoke :export_cms_nodes
    invoke :export_cms_parts
    invoke :export_cms_pages
    invoke :export_cms_loop_settings
    invoke :export_ezine_columns
    invoke :export_inquiry_columns
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
end
