module Sys::SiteCopy::CmsPages
  extend ActiveSupport::Concern
  include SS::Copy::CmsPages
  include Sys::SiteCopy::CmsContents

  def copy_cms_page(src_page)
    return nil if (src_page.route != "cms/page") && !@copy_contents.include?('pages')

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
end
