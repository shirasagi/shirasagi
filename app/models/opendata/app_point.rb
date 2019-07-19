class Opendata::AppPoint
  include SS::Document
  include History::Addon::Trash

  belongs_to :site, class_name: "SS::Site"
  belongs_to :member, class_name: "Opendata::Member"
  belongs_to :app, class_name: "Opendata::App", inverse_of: :points

  validates :site_id, presence: true
  validates :member_id, presence: true
  validates :app_id, presence: true
end
