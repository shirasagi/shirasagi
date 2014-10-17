class Opendata::DatasetPoint
  include SS::Document

  field :site_id, type: Integer
  field :member_id, type: Integer
  field :dataset_id, type: Integer

  validates :site_id, presence: true
  validates :member_id, presence: true
  validates :dataset_id, presence: true
end
