module Sys::SiteCopy::OpendataDatasetGroups
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache
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

  def copy_opendata_dataset_group(src_content)
    dest_content = nil
    id = cache(:opendata_dataset_groups, src_content.id) do
      dest_content = Opendata::DatasetGroup.site(@dest_site).where(name: src_content.name).first
      return dest_content.id if dest_content.present?

      dest_content = Opendata::DatasetGroup.new(cur_site: @dest_site)
      dest_content.attributes = copy_basic_attributes(src_content, Opendata::DatasetGroup)
      dest_content.attributes.merge(resolve_unsafe_references(src_content, Opendata::DatasetGroup))
      dest_content.save!
      dest_content.id
    end

    dest_content ||= Opendata::DatasetGroup.site(@dest_site).find(id) if id
    dest_content
  rescue => e
    @task.log("#{src_page.filename}(#{src_page.id}): データセットグループのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
