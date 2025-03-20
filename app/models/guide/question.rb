class Guide::Question < Guide::Diagram::Point
  include Cms::SitePermission
  include Guide::Addon::Question

  attr_accessor :row_index # for import

  set_permission_name "guide_questions"

  seqid :id

  default_scope -> { order_by(order: 1, name: 1) }

  def type
    "question"
  end

  def name_with_type
    I18n.t("guide.labels.question_name", name: id_name)
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
