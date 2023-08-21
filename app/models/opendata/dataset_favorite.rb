class Opendata::DatasetFavorite
  include SS::Document
  include SS::Reference::Site
  include Opendata::Reference::Member
  include History::Addon::Trash

  belongs_to :dataset, class_name: "Opendata::Dataset"
  validates :dataset_id, presence: true
end
