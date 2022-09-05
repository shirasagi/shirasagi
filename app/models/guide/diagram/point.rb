class Guide::Diagram::Point
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Reference::Node

  attr_accessor :transitions, :weight

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

  def export_label
    procedure? ? "[#{I18n.t("guide.procedure")}] #{id_name}" : "[#{I18n.t("guide.question")}] #{id_name}"
  end

  def procedure?
    self._type == "Guide::Procedure"
  end

  def question?
    self._type == "Guide::Question"
  end
end
