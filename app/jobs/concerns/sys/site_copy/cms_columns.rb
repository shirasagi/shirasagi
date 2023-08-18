module Sys::SiteCopy::CmsColumns
  extend ActiveSupport::Concern
  include SS::Copy::CmsColumns
  include Sys::SiteCopy::CmsContents

  def resolve_column_reference(id)
    cache(:columns, id) do
      src_item = Cms::Column::Base.site(@src_site).find(id) rescue nil
      if src_item.blank?
        Rails.logger.warn("#{id}: 参照されている入力項目が存在しません。")
        return nil
      end

      dest_item = copy_cms_column(src_item)
      dest_item.try(:id)
    end
  end
end
