class Opendata::Member
  include Cms::Model::Member
  include SS::Relation::File

  belongs_to_file :icon, static_state: 'public', resizing: [ 114, 114 ]
  permit_params :in_icon

  has_one :points, primary_key: :member_id, class_name: "Opendata::MemberNotice",
    dependent: :destroy

  validates :email, uniqueness: { scope: :site_id }, if: ->{ email.present? }
end
