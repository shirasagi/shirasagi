class Gws::StaffRecord::Year
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  seqid :id
  field :name, type: String
  field :code, type: String
  field :start_date, type: Date
  field :close_date, type: Date

  has_many :yearly_groups, class_name: 'Gws::StaffRecord::Group', dependent: :destroy
  has_many :yearly_users, class_name: 'Gws::StaffRecord::User', dependent: :destroy
  has_many :yearly_seatings, class_name: 'Gws::StaffRecord::Seating', dependent: :destroy
  has_many :yearly_user_titles, class_name: 'Gws::StaffRecord::UserTitle', dependent: :destroy

  permit_params :code, :name, :start_date, :close_date

  validates :code, presence: true, uniqueness: { scope: :site_id }
  validates :name, presence: true, uniqueness: { scope: :site_id }
  validates :start_date, presence: true, datetime: true
  validates :close_date, presence: true, datetime: true

  default_scope -> { order_by start_date: -1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :code, :name
    end
    criteria
  }

  def name_with_code
    "#{name} (#{code})"
  end
end
