class Cms::ContentImportJob < Sys::SiteImportJob

  self.task_name = 'cms:import_content'

  def perform(opts = {})
    @dst_site = Cms::Site.find(@task.site_id)

    if opts[:file].present?
      @import_zip = "#{Rails.root}/private/import/#{opts[:file]}"
    else
      @import_zip = @task.import_file
    end
    @import_dir = "#{Rails.root}/private/import/content-#{@dst_site.host}"

    @task.log("=== Content Import ===")
    @task.log("Site name: #{@dst_site.name}")
    @task.log("Temporary directory: #{@import_dir}")
    @task.log("Import file: #{@import_zip}")

    invoke :extract

    init_src_site
    init_mapping
    import_cms_groups
    import_cms_users
    import_dst_site

    if @dst_site.errors.present?
      @task.log("Error: Could not create the site. #{@dst_site.name}")
      @task.log(@dst_site.errors.full_messages.join(' '))
      return
    end

    invoke :import_ss_files
    invoke :import_cms_forms
    invoke :import_cms_columns
    invoke :import_cms_loop_settings
    invoke :import_cms_layouts
    invoke :import_cms_body_layouts
    invoke :import_cms_nodes
    invoke :import_cms_parts
    invoke :import_cms_pages
    invoke :import_ezine_columns
    invoke :import_inquiry_columns
    invoke :import_opendata_dataset_groups
    invoke :import_opendata_licenses
    invoke :update_cms_nodes
    invoke :update_cms_pages
    invoke :update_ss_files
    invoke :update_opendata_dataset_resources
    invoke :update_opendata_app_appfiles
    invoke :update_ss_files_url

    FileUtils.rm_rf(@import_dir)
    @task.log("Completed.")
  end
end
