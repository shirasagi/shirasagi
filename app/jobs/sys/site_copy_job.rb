class Sys::SiteCopyJob < SS::ApplicationJob
  include Job::SS::TaskFilter
  include Sys::SiteCopy::SsFiles
  include Sys::SiteCopy::CmsRoles
  include Sys::SiteCopy::CmsLayouts
  include Sys::SiteCopy::CmsNodes
  include Sys::SiteCopy::CmsParts
  include Sys::SiteCopy::CmsPages
  include Sys::SiteCopy::CmsFiles
  include Sys::SiteCopy::CmsEditorTemplates
  include Sys::SiteCopy::KanaDictionaries

  self.task_class = Sys::SiteCopyTask
  self.task_name = "sys::site_copy"

  attr_accessor :src_site, :dest_site, :copy_options

  def perform
    Rails.logger.info("サイト複製処理を開始します。#{Sys::SiteCopyTask.t :copy_contents}: #{@copy_contents}")

    @src_site = Cms::Site.find(@task.source_site_id)
    @copy_contents = @task.copy_contents
    dest_site_params = {
      name: @task.target_host_name,
      host: @task.target_host_host,
      domains: @task.target_host_domains }
    @dest_site = Cms::Site.create(dest_site_params.merge(group_ids:  @src_site.group_ids))
    @task.log("サイト #{@dest_site.host} を作成しました。")
    Rails.logger.debug("サイト #{@src_site.host} を #{@dest_site.host} へコピーします。")

    copy_cms_roles
    copy_cms_layouts
    copy_cms_nodes
    copy_cms_parts
    copy_cms_pages
    copy_cms_files if @copy_contents.include?("files")
    copy_cms_editor_templates if @copy_contents.include?("editor_templates")
    copy_kana_dictionaries if @copy_contents.include?("dictionaries")

    @task.log("サイト #{@src_site.host} を #{@dest_site.host} へコピーしました。")
  end
end