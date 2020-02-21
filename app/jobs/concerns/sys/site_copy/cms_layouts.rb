module Sys::SiteCopy::CmsLayouts
  extend ActiveSupport::Concern
  include SS::Copy::CmsLayouts
  include Sys::SiteCopy::CmsContents

  def copy_cms_layouts
    layout_ids = Cms::Layout.site(@src_site).pluck(:id)
    layout_ids.each do |layout_id|
      layout = Cms::Layout.site(@src_site).find(layout_id) rescue nil
      next if layout.blank?
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
end
