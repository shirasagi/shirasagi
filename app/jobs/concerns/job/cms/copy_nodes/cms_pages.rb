module Job::Cms::CopyNodes::CmsPages
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache
  include Job::Cms::CopyNodes::CmsContents

  def copy_cms_page(src_page)
    src_page = src_page.becomes_with_route
    copy_cms_content(:pages, src_page, copy_cms_page_options)
  rescue => e
    @task.log("#{src_page.filename}(#{src_page.id}): ページのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def copy_cms_pages
    Cms::Page.site(@cur_site).where(filename: /^#{@cur_node.filename}\//).each do |page|
      copy_cms_page(page)
    end
  end

  def resolve_page_reference(id)
    id
  end

  private

  def copy_cms_page_options
    {
      before: method(:before_copy_cms_page),
      after: method(:after_copy_cms_page)
    }
  end

  def before_copy_cms_page(src_page)
    @task.log("#{src_page.filename}(#{src_page.id}): ページのコピーを開始します。")
  end

  def after_copy_cms_page(src_page, dest_page)
    @task.log("#{dest_page.filename}(#{dest_page.id}): ページをコピーしました。")
  end
end
