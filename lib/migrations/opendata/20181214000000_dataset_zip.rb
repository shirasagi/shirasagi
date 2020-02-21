class SS::Migration20181214000000
  include SS::Migration::Base

  depends_on "20181128000000"

  def change
    dataset_ids = Opendata::Dataset.pluck(:id)
    dataset_ids.each do |id|
      item = Opendata::Dataset.find(id) rescue nil
      next unless item
      item.send(:compression_dataset)
    end
  end
end
