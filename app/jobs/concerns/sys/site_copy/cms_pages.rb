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
    Cms::Page.site(@src_site).each do |page|
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
    @task.log("#{src_page.filename}(#{src_page.id}): ページをコピーしました。")
  end
end
