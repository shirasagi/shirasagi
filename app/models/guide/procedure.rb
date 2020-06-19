class Guide::Procedure < Guide::Diagram::Point
  include Cms::SitePermission
  include SS::TemplateVariable
  include SS::Liquidization
  include Guide::Addon::Procedure

  set_permission_name "guide_procedures"

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0

  permit_params :name
  permit_params :order

  validates :name, presence: true

  default_scope -> { order_by(order: 1, name: 1) }

  def type
    "procedure"
  end

  def name_with_type
    "[手続き] #{name}"
  end

  class << self
    def search(params = {})
      criteria = self.all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      if params[:genre_id].present?
        criteria = criteria.in(genre_ids: [params[:genre_id].try(:to_i)])
      end
      criteria
    end
  end
end
