class Cms::Line::DeliverCondition
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Addon::Line::DeliverCondition::Body
  include Cms::Addon::GroupPermission

  set_permission_name "cms_line_messages", :use

  seqid :id

  field :name
  field :order, type: Integer, default: 0
  permit_params :name, :order

  validates :name, presence: true
  validate :validate_condition_body

  default_scope -> { order_by(order: 1) }

  def name_with_order
    [order, name].select(&:present?).join(". ").to_s
  end

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

  def root_owned?(user)
    true
  end

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end
end
