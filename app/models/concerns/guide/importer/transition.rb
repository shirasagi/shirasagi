module Guide::Importer::Transition
  extend ActiveSupport::Concern

  def import_transitions
    return false unless validate_import

    @row_index = 0
    self.class.each_csv(in_file) do |row|
      @row_index += 1
      @row = row
      save_transition
    end

    errors.empty?
  end

  def transitions_enum
    Enumerator.new do |y|
      headers = %w(id_name name).map { |v| Guide::Question.t(v) }
      edge_size = Guide::Question.site(cur_site).node(cur_node).map { |item| item.edges.size }.max
      edge_size.times { |i| headers << "#{I18n.t("guide.transition")}#{i + 1}" } if edge_size

      y << encode_sjis(headers.to_csv)
      Guide::Question.site(cur_site).node(cur_node).each do |item|
        row = []
        row << item.id_name
        row << item.name
        item.edges.map do |edge|
          edge.parent = item
          labels = []
          labels << edge.export_label
          edge.points.each do |point|
            labels << point.export_label(edge)
          end
          row << labels.join("\n")
        end
        y << encode_sjis(row.to_csv)
      end
    end
  end

  def save_transition
    id_name = @row[Guide::Question.t(:id_name)]
    item = Guide::Question.site(cur_site).node(cur_node).where(id_name: id_name).first

    if item.nil?
      errors.add :base, "#{@row_index}: #{I18n.t("guide.errors.not_found_question", id: id_name)}"
      return false
    end

    edge_headers.each do |v, idx|
      v = @row[v]
      next if v.blank?

      if !item.edges[idx]
        errors.add :base,
          "#{@row_index}: #{I18n.t("guide.errors.not_found_transition", id: "#{I18n.t("guide.transition")}#{idx + 1}")}"
        return false
      end

      v.split(/\n/).each do |line|
        line.scan(/^\[(.+?)\](.+?)$/).each do |type, id_name|
          id_name = id_name.squish
          type = type.squish

          next unless type.match?(/#{::Regexp.escape(I18n.t("guide.procedure"))}/)

          point = Guide::Procedure.site(cur_site).node(cur_node).where(id_name: id_name).first
          point.add_to_set(
            cond_yes_question_ids: item.id,
            cond_yes_edge_values: { question_id: item.id.to_s, edge_value: item.edges[idx][:value] }
          )
          if type.match?(I18n.t("guide.labels.not_applicable"))
            point.add_to_set(
              cond_no_question_ids: item.id,
              cond_no_edge_values: { question_id: item.id.to_s, edge_value: initem.edges_edges[idx][:value] }
            )
          end
          if type.match?(I18n.t("guide.labels.optional_necessary"))
            point.add_to_set(
              cond_or_question_ids: item.id,
              cond_or_edge_values: { question_id: item.id.to_s, edge_value: item.edges[idx][:value] }
            )
          end
          point
        end
      end
    end
  end
end
