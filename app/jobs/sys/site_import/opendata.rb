module Sys::SiteImport::Opendata
  extend ActiveSupport::Concern

  def import_opendata_dataset_groups
    import_documents "opendata_dataset_groups", Opendata::DatasetGroup do |item|
      item[:category_ids] = convert_ids(@cms_nodes_map, item[:category_ids])
    end
  end

  def import_opendata_licenses
    @opendata_licenses_map = import_documents "opendata_licenses", Opendata::License
  end

  def update_opendata_dataset_resources
    Opendata::Dataset.site(@dst_site).pluck(:id).each do |id|
      item = Opendata::Dataset.find(id)
      item.resources.each do |resource|
        resource.set(
          file_id: @ss_files_map[resource.file_id],
          license_id: @opendata_licenses_map[resource.license_id]
        )
      end
      item.url_resources.each do |resource|
        resource.set(
          file_id: @ss_files_map[resource.file_id],
          license_id: @opendata_licenses_map[resource.license_id]
        )
      end
    end
  end

  def update_opendata_app_appfiles
    Opendata::App.site(@dst_site).pluck(:id).each do |id|
      item = Opendata::App.find(id)
      item.appfiles.each do |resource|
        resource.set(file_id: @ss_files_map[resource.file_id])
      end
    end
  end
end
