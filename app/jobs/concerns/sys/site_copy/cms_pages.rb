module Sys::SiteCopy::CmsPages
  extend ActiveSupport::Concern
  include SS::Copy::CmsPages
  include Sys::SiteCopy::CmsContents

  def copy_cms_page(src_page)
    Rails.logger.debug{ "[copy_cms_page] コピー開始: #{src_page.filename}(#{src_page.id}), route: #{src_page.route}" }
    Rails.logger.debug{ "[copy_cms_page] @copy_contents=#{@copy_contents.inspect} (class=#{@copy_contents.class})" }
    return nil if (src_page.route != "cms/page") && !@copy_contents.include?('pages')

    copy_cms_content(:pages, src_page, copy_cms_page_options)
  rescue => e
    @task.log("#{src_page.filename}(#{src_page.id}): ページのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def copy_cms_pages
    page_ids = Cms::Page.site(@src_site).pluck(:id)
    Rails.logger.debug{ "[copy_cms_pages] コピー対象ページ数: #{page_ids.size}" }
    page_ids.each do |page_id|
      page = Cms::Page.site(@src_site).find(page_id) rescue nil
      next if page.blank?
      Rails.logger.debug{ "[copy_cms_pages] ページコピー開始: #{page.filename} (#{page.id})" }
      copy_cms_page(page)
      Rails.logger.debug{ "[copy_cms_pages] ページコピー終了: #{page.filename} (#{page.id})" }
    end
  end
  def resolve_page_reference(id)
    cache(:pages, id) do
      src_page = Cms::Page.site(@src_site).find(id) rescue nil
      if src_page.blank?
        Rails.logger.debug{ "[resolve_page_reference] #{id}: 参照されているページが存在しません。" }
        return nil
      end

      Rails.logger.debug{ "[resolve_page_reference] 参照ページコピー開始: #{src_page.filename} (#{src_page.id})" }
      dest_page = copy_cms_page(src_page)
      Rails.logger.debug{ "[resolve_page_reference] コピー後の dest_page: #{dest_page&.id}" }
      Rails.logger.debug{ "[resolve_page_reference] 終了時の dest_page: #{dest_page.inspect}" }
      dest_page.try(:id)
    end
  end
end
