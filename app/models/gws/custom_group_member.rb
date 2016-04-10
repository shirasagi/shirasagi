class Gws::CustomGroupMember
  include SS::Document
  include SS::Fields::Normalizer
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  attr_accessor :member_ids

  seqid :id
  field :order, type: Integer, default: 0

  belongs_to :custom_group, class_name: "Gws::CustomGroup"
  belongs_to :member, class_name: "Gws::User"

  permit_params :order, :member_id, member_ids: []

  validates :custom_group_id, presence: true
  validates :member_id, presence: true, uniqueness: { scope: [:site_id, :custom_group_id, :member_id] }

  default_scope ->{ order_by order: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:keyword].present?
      site = Gws::Group.where(id: criteria.selector["site_id"]).first
      uids = Gws::User.site(site).search(keyword: params[:keyword]).pluck(:id)
      criteria = criteria.any_in(user_id: uids)
    end

    criteria
  }

  def uid
    member ? member.uid : nil
  end

  def name
    member ? member.name : "User Not Found"
  end

  def email
    member ? member.email : nil
  end

  def tel
    member ? member.tel : nil
  end

  def allowed?(action, user, opts = {})
    custom_group.allowed?(action, user, opts)
  end

  def save_members
    if member_ids.blank?
      errors.add :member_id, :blank
      return false
    end

    member_ids.each do |member_id|
      item = self.class.new(attributes)
      item.attributes = {
        cur_user: cur_user,
        cur_site: cur_site,
        member_id: member_id
      }
      item.save
    end

    true
  end

  class << self
    def allowed?(action, user, opts = {})
      true
    end
  end
end
