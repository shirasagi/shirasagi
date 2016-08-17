module Sys::SiteCopy::CmsPages
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache
  include Sys::SiteCopy::CmsContents

  def copy_cms_page(src_page)
    return nil if (src_page.route != "cms/page") && !@copy_contents.include?('pages')

    src_page = src_page.becomes_with_route
    copy_cms_content(:pages, src_page, copy_cms_page_options)
  rescue => e
    @task.log("#{src_page.filename}(#{src_page.id}): ページのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def copy_cms_pages
    page_ids = Cms::Page.site(@src_site).pluck(:id)
    page_ids.each do |page_id|
      page = Cms::Page.site(@src_site).find(page_id) rescue nil
      next if page.blank?
      copy_cms_page(page)
    end
  end

  def resolve_page_reference(id)
    cache(:pages, id) do
      src_page = Cms::Page.site(@src_site).find(id) rescue nil
      if src_page.blank?
        Rails.logger.warn("#{id}: 参照されているページが存在しません。")
        return nil
      end

      dest_page = copy_cms_page(src_page)
      dest_page.try(:id)
    end
  end

  private

  def copy_cms_page_options
    {
      before: method(:before_copy_cms_page),
      after: method(:after_copy_cms_page)
    }
  end

  def before_copy_cms_page(src_page)
    Rails.logger.debug("#{src_page.filename}(#{src_page.id}): ページのコピーを開始します。")
  end

  def after_copy_cms_page(src_page, dest_page)
    case src_page.route
    when "opendata/dataset"
      copy_opendata_dataset_groups(src_page, dest_page)
      copy_opendata_dataset_resources(src_page, dest_page)
    when "opendata/app"
      copy_opendata_app_appfiles(src_page, dest_page)
    end

    @task.log("#{src_page.filename}(#{src_page.id}): ページをコピーしました。")
  end

  def copy_opendata_dataset_groups(src_page, dest_page)
    dest_page.dataset_group_ids = src_page.dataset_groups.map do |dataset_group|
      resolve_opendata_dataset_group_reference(dataset_group.id)
    end

    dest_page.save!
  end

  def copy_opendata_dataset_resources(src_page, dest_page)
    cache(:opendata_dataset_resources, src_page.id) do
      src_page.resources.each do |resource|
        dest_resource = dest_page.resources.new
        dest_resource.name = resource.name
        dest_resource.text = resource.text
        dest_resource.filename = resource.filename
        dest_resource.format = resource.format
        dest_resource.rdf_iri = resource.rdf_iri
        dest_resource.rdf_error = resource.rdf_error
        dest_resource.license_id = resolve_opendata_license_reference(resource.license_id) if resource.license_id.present?
        dest_resource.file_id = resolve_file_reference(resource.file_id) if resource.file_id.present?
        dest_resource.tsv_id = resolve_file_reference(resource.tsv_id) if resource.tsv_id.present?
        dest_resource.assoc_site_id = resource.assoc_site_id
        dest_resource.assoc_node_id = resource.assoc_node_id
        dest_resource.assoc_page_id = resource.assoc_page_id
        dest_resource.assoc_file_id = resource.assoc_file_id
        dest_resource.save!(validate: false)
      end
      dest_page.id
    end
  end

  def copy_opendata_app_appfiles(src_page, dest_page)
    cache(:opendata_app_appfiles, src_page.id) do
      src_page.appfiles.each do |appfile|
        dest_appfile = dest_page.appfiles.new
        dest_appfile.text = appfile.text
        dest_appfile.filename = appfile.filename
        dest_appfile.format = appfile.format
        dest_appfile.file_id = resolve_file_reference(appfile.file_id) if appfile.file_id.present?
        dest_appfile.save!
      end
      dest_page.id
    end
  end
end
