class Gws::Schedule::Category
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission

  field :name, type: String
  field :bg_color, type: String, default: "#48b"
  field :text_color, type: String, default: "#fff"

  has_many :plans, class_name: 'Gws::Schedule::Plan', dependent: :destroy

  permit_params :name, :bg_color, :text_color

  validates :name, presence: true
  validates :bg_color, presence: true
  validates :text_color, presence: true
end
