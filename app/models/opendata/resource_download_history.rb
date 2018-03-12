class Opendata::ResourceDownloadHistory
  include SS::Document

  field :dataset_id, type: Integer
  field :resource_id, type: Integer
  field :downloaded, type: DateTime

  def self.create_download_history(dataset_id:, resource_id:)
    self.create(
      dataset_id: dataset_id,
      resource_id: resource_id,
      downloaded: Time.zone.now
    )
  end
end
