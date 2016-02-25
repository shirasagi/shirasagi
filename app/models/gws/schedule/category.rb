class Gws::Schedule::Category
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Content::Targetable
  include Gws::Addon::GroupPermission

  field :state, type: String, default: "public"
  field :name, type: String
  field :color, type: String, default: "#48b"

  has_many :plans, class_name: 'Gws::Schedule::Plan', dependent: :destroy

  permit_params :state, :name, :color

  validates :state, presence: true
  validates :name, presence: true
  validates :color, presence: true

  default_scope -> {
    order_by name: 1
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria
  }

  def brightness
    color = self.color.sub(/^#/, '').sub(/^(.)(.)(.)$/, '\\1\\1\\2\\2\\3\\3')
    r, g, b = color.scan(/../).map { |c| c.hex }
    ((r * 299) + (g * 587) + (b * 114)).to_f / 1000
  end

  def text_color
    bgb = brightness
    (255 - bgb > bgb - 0) ? "#ffffff" : "#000000"
  end
end
