class SS::Migration20181126000000
  include SS::Migration::Base

  depends_on "20181015000001"

  def change
    dataset_ids = Opendata::Dataset.pluck(:id)
    dataset_ids.each do |id|
      dataset = Opendata::Dataset.find(id) rescue nil
      next unless dataset

      dataset.resources.each do |resource|
        next if resource.file.nil?

        resource.send(:save_map_resources)
        #next if resource.map_resources.blank?

        resource.set(map_resources: resource.map_resources)
      end
    end
  end
end
