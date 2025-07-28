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

  def points
    or_cond = [
      { cond_yes_edge_values: { "$elemMatch" => { question_id: self.parent.id.to_s, edge_value: self.value } } },
      { cond_no_edge_values: { "$elemMatch" => { question_id: self.parent.id.to_s, edge_value: self.value } } },
      { cond_or_edge_values: { "$elemMatch" => { question_id: self.parent.id.to_s, edge_value: self.value } } }
    ]
    Guide::Diagram::Point.where("$and" => [{ "$or" => or_cond }])
  end

  def applicable_points
    or_cond = [
      { cond_yes_edge_values: { "$elemMatch" => { question_id: self.parent.id.to_s, edge_value: self.value } } },
      { cond_or_edge_values: { "$elemMatch" => { question_id: self.parent.id.to_s, edge_value: self.value } } }
    ]
    Guide::Diagram::Point.where("$and" => [{ "$or" => or_cond }])
  end

  def not_applicable_points
    or_cond = [
      { cond_no_edge_values: { "$elemMatch" => { question_id: self.parent.id.to_s, edge_value: self.value } } },
    ]
    Guide::Diagram::Point.where("$and" => [{ "$or" => or_cond }])
  end
  alias not_necessary_points not_applicable_points

  def necessary_points
    or_cond = [
      { cond_yes_edge_values: { "$elemMatch" => { question_id: self.parent.id.to_s, edge_value: self.value } } }
    ]
    Guide::Diagram::Point.where("$and" => [{ "$or" => or_cond }])
  end

  def optional_necessary_points
    or_cond = [
      { cond_or_edge_values: { "$elemMatch" => { question_id: self.parent.id.to_s, edge_value: self.value } } }
    ]
    Guide::Diagram::Point.where("$and" => [{ "$or" => or_cond }])
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
      errors.add :base, I18n.t("guide.errors.already_registered", name: point.name)
      break
    end
  end
end
