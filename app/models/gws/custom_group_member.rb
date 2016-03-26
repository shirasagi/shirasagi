class Gws::CustomGroupMember
  include SS::Document
  include SS::Fields::Normalizer
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  seqid :id
  field :order, type: Integer, default: 0

  belongs_to :custom_group, class_name: "Gws::CustomGroup"
  belongs_to :member, class_name: "Gws::User"

  permit_params :order, :member_id

  validates :custom_group_id, presence: true
  validates :member_id, presence: true

  default_scope ->{ order_by order: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    #criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
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

  class << self
    def allowed?(action, user, opts = {})
      true
    end
  end
end
