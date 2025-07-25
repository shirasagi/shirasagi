class SS::Migration20250725000000
  include SS::Migration::Base

  depends_on "20250609000000"

  def change
    each_question do |question|
      question.edges.each do |edge|
        edge[:point_ids].each do |point_id|
          procedure = Guide::Procedure.site(question.site).
            node(question.node).
            where(id: point_id).
            first

          next unless procedure

          if edge[:not_applicable_point_ids].to_a.include?(point_id)
            procedure.add_to_set(
              cond_no_question_ids: question.id,
              cond_no_edge_values: { question_id: question.id.to_s, edge_value: edge.value }
            )
          elsif edge[:optional_necessary_point_ids].to_a.include?(point_id) || question.updated < Time.zone.parse('2024/09/05')
            procedure.add_to_set(
              cond_or_question_ids: question.id,
              cond_or_edge_values: { question_id: question.id.to_s, edge_value: edge.value }
            )
          else
            procedure.add_to_set(
              cond_yes_question_ids: question.id,
              cond_yes_edge_values: { question_id: question.id.to_s, edge_value: edge.value }
            )
          end
        end
      end
    end
  end

  private

  def each_question(&block)
    criteria = Guide::Question.all
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
