module Sys::SiteCopy::CmsForms
  extend ActiveSupport::Concern
  include SS::Copy::CmsForms
  include Sys::SiteCopy::CmsContents

  def resolve_form_reference(id)
    cache(:forms, id) do
      src_item = Cms::Form.site(@src_site).find(id) rescue nil
      if src_item.blank?
        Rails.logger.warn("#{id}: 参照されている定型フォームが存在しません。")
        return nil
      end

      dest_item = copy_cms_form(src_item)
      dest_item.try(:id)
    end
  end
end
