module Job::Cms::CopyNodes::CmsLayouts
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache

  def resolve_layout_reference(id)
    cache(:layouts, id) do
      cur_layout = Cms::Layout.site(@cur_site).find(id) rescue nil
      if cur_layout.blank?
        Rails.logger.warn("#{id}: 参照されているレイアウトが存在しません。")
        return nil
      end

      cur_layout.try(:id)
    end
  end
end
