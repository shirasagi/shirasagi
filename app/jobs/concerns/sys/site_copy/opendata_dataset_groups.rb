module Sys::SiteCopy::OpendataDatasetGroups
  extend ActiveSupport::Concern
  include SS::Copy::OpendataDatasetGroups
  include Sys::SiteCopy::CmsContents

  def resolve_opendata_dataset_group_reference(id)
    cache(:opendata_dataset_groups, id) do
      src_content = Opendata::DatasetGroup.site(@src_site).find(id) rescue nil
      if src_content.blank?
        Rails.logger.warn("#{id}: 参照されているデータセットグループが存在しません。")
        return nil
      end

      dest_content = copy_opendata_dataset_group(src_content)
      dest_content.try(:id)
    end
  end
end
