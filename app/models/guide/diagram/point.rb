class Guide::Diagram::Point
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Reference::Node

  attr_accessor :transitions, :applicable_transitions, :not_applicable_transitions, :necessary_transitions,
    :optional_necessary_transitions

  field :name, type: String
  field :id_name, type: String
  field :explanation, type: String
  field :order, type: Integer, default: 0

  permit_params :name
  permit_params :id_name
  permit_params :explanation
  permit_params :order

  validates :name, presence: true
  validates :id_name, presence: true, uniqueness: { scope: :node_id }

  default_scope -> { order_by(_type: -1, order: 1, name: 1) }

  store_in collection: "guide_diagram_point"

  def export_label(edge = nil)
    label = [procedure? ? I18n.t("guide.procedure") : I18n.t("guide.question")]
    if edge
      if edge.not_applicable_point_ids.include?(id)
        label << I18n.t('guide.labels.not_applicable')
      end
      if edge.optional_necessary_point_ids.include?(id)
        label << I18n.t('guide.labels.optional_necessary')
      end
    end
    "[#{label.join(':')}] #{id_name}"
  end

  def procedure?
    self._type == "Guide::Procedure"
  end

  def question?
    self._type == "Guide::Question"
  end
end
