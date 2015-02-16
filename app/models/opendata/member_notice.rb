class Opendata::MemberNotice
  include SS::Document

  field :member_id, type: Integer
  field :commented_count, type: Integer, default: "0"
  field :confirmed, type: DateTime

  belongs_to :site, class_name: "SS::Site"
  belongs_to :member, class_name: "Opendata::Member"

  validates :site_id, presence: true
  validates :member_id, presence: true

end
