class Guide::Diagram::Edge
  include SS::Document

  attr_accessor :parent

  field :value, type: String
  field :transition, type: String
  field :question_type, type: String
  field :explanation, type: String

  validates :value, presence: true
  validates :transition, presence: true
  validates :question_type, presence: true

  embeds_ids :points, class_name: "Guide::Diagram::Point"
  embeds_ids :not_applicable_points, class_name: "Guide::Diagram::Point"
  embeds_ids :optional_necessary_points, class_name: "Guide::Diagram::Point"

  def applicable_points
    points.nin(id: not_applicable_point_ids)
  end

  def necessary_points
    points.nin(id: optional_necessary_point_ids)
  end

  def export_label
    "[#{I18n.t("guide.transition")}] #{value}"
  end

  def procedures
    points.where(_type: "Guide::Procedure")
  end

  def questions
    points.where(_type: "Guide::Question")
  end

  private

  def validate_points
    points.each do |point|
      next if !point.question?
      next if point.referenced_questions.nin(id: parent.id).blank?
      errors.add :base, I18n.t("guide.errors.already_registered", name: point.name)
      break
    end
  end
end
