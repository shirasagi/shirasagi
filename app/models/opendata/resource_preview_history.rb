class Opendata::ResourcePreviewHistory
  include SS::Document

  field :dataset_id, type: Integer
  field :resource_id, type: Integer
  field :previewed, type: DateTime

  def self.create_preview_history(dataset_id:, resource_id:)
    self.create(
      dataset_id: dataset_id,
      resource_id: resource_id,
      previewed: Time.zone.now
    )
  end
end
