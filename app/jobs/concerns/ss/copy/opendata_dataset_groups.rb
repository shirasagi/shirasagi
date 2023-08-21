module SS::Copy::OpendataDatasetGroups
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def resolve_opendata_dataset_group_reference(id)
    id
  end

  def copy_opendata_dataset_group(src_content)
    dest_content = nil
    id = cache(:opendata_dataset_groups, src_content.id) do
      dest_content = Opendata::DatasetGroup.site(@dest_site).where(name: src_content.name).first
      return dest_content if dest_content.present?

      dest_content = Opendata::DatasetGroup.new(cur_site: @dest_site)
      dest_content.attributes = copy_basic_attributes(src_content, Opendata::DatasetGroup)
      dest_content.save!
      dest_content.id
    end

    if dest_content
      dest_content.attributes = resolve_unsafe_references(src_content, Opendata::DatasetGroup)
      dest_content.save!
    end

    dest_content ||= Opendata::DatasetGroup.site(@dest_site).find(id) if id
    dest_content
  rescue => e
    @task.log("#{src_content.name}(#{src_content.id}): データセットグループのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
