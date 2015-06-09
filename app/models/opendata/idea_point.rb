class Opendata::IdeaPoint
  include SS::Document

  belongs_to :site, class_name: "SS::Site"
  belongs_to :member, class_name: "Opendata::Member"
  belongs_to :idea, class_name: "Opendata::Idea"

  validates :site_id, presence: true
  validates :member_id, presence: true
  validates :idea_id, presence: true
end
