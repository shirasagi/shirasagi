module Sys::SiteCopy::CmsLayouts
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache
  include Sys::SiteCopy::CmsContents

  def copy_cms_layout(src_layout)
    copy_cms_content(:layouts, src_layout, copy_cms_layout_options)
  rescue => e
    @task.log("#{src_layout.filename}(#{src_layout.id}): レイアウトのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def copy_cms_layouts
    Cms::Layout.site(@src_site).each do |layout|
      copy_cms_layout(layout)
    end
  end

  def resolve_layout_reference(id)
    cache(:layouts, id) do
      src_layout = Cms::Layout.site(@src_site).find(id) rescue nil
      if src_layout.blank?
        Rails.logger.warn("#{id}: 参照されているレイアウトが存在しません。")
        return nil
      end

      dest_layout = copy_cms_layout(src_layout)
      dest_layout.try(:id)
    end
  end

  private

  def copy_cms_layout_options
    {
      before: method(:before_copy_cms_layout),
      after: method(:after_copy_cms_layout)
    }
  end

  def before_copy_cms_layout(src_layout)
    Rails.logger.debug("#{src_layout.filename}(#{src_layout.id}): レイアウトのコピーを開始します。")
  end

  def after_copy_cms_layout(src_layout, dest_layout)
    @task.log("#{src_layout.filename}(#{src_layout.id}): レイアウトをコピーしました。")
  end
end
