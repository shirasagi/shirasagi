module Sys::SiteCopy::CmsParts
  extend ActiveSupport::Concern
  include SS::Copy::CmsParts
  include Sys::SiteCopy::CmsContents

  def copy_cms_parts
    part_ids = Cms::Part.site(@src_site).pluck(:id)
    part_ids.each do |part_id|
      part = Cms::Part.site(@src_site).find(part_id) rescue nil
      next if part.blank?
      copy_cms_part(part)
    end
  end

  def resolve_part_reference(id)
    cache(:parts, id) do
      src_part = Cms::Part.site(@src_site).find(id) rescue nil
      if src_part.blank?
        Rails.logger.warn("#{id}: 参照されているパーツが存在しません。")
        return nil
      end

      dest_part = copy_cms_part(src_part)
      dest_part.try(:id)
    end
  end
end
