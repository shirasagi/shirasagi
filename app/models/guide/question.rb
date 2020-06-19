class Guide::Question < Guide::Diagram::Point
  include Cms::SitePermission
  include Guide::Addon::Question

  set_permission_name "guide_questions"

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0

  permit_params :name
  permit_params :order

  validates :name, presence: true

  default_scope -> { order_by(order: 1, name: 1) }

  def type
    "question"
  end

  def name_with_type
    "[質問] #{name}"
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
      criteria
    end
  end
end
