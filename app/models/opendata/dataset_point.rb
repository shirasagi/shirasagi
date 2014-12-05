class Opendata::DatasetPoint
  include SS::Document

  belongs_to :site, class_name: "SS::Site"
  belongs_to :member, class_name: "Cms::Member"
  belongs_to :dataset, class_name: "Opendata::Dataset"

  validates :site_id, presence: true
  validates :member_id, presence: true
  validates :dataset_id, presence: true
end
