class Opendata::AppPoint
  include SS::Document

  belongs_to :site, class_name: "SS::Site"
  belongs_to :member, class_name: "Opendata::Member"
  belongs_to :app, class_name: "Opendata::App"

  validates :site_id, presence: true
  validates :member_id, presence: true
  validates :app_id, presence: true
end
