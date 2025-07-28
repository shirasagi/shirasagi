class Gws::Workload::Category
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Workload::Yearly
  include Gws::Addon::Workload::Member
  include Gws::SitePermission
  include Gws::Addon::History

  set_permission_name 'gws_workload_settings', :edit

  class_variable_set(:@@_member_include_member_ids, false)

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :order

  validates :name, presence: true

  default_scope -> { order_by order: 1, name: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name
    end

    criteria = criteria.search_year(params)
    criteria
  }

  private

  def validate_presence_member
    errors.add :member_group_ids, :blank if member_group_ids.blank?
  end

  class << self
    def use_member_ids?
      false
    end
  end
end
