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

    in_edges = item.edges.map do |edge|
      OpenStruct.new(
        question_type: edge.question_type,
        value: edge.value,
        explanation: edge.explanation,
        point_ids: edge.point_ids,
        not_applicable_point_ids: edge.not_applicable_point_ids,
        optional_necessary_point_ids: edge.optional_necessary_point_ids
      )
    end

    edge_headers.each do |v, idx|
      v = @row[v]
      next if v.blank?

      if !in_edges[idx]
        errors.add :base, "#{@row_index}: #{I18n.t("guide.errors.not_found_transition", id: "#{I18n.t("guide.transition")}#{idx + 1}")}"
        return false
      end

      point_ids = []
      not_applicable_point_ids = []
      optional_necessary_point_ids = []
      v.split(/\n/).each do |line|
        line.scan(/^\[(.+?)\](.+?)$/).each do |type, id_name|
          id_name = id_name.squish
          type = type.squish

          case type
          when /#{::Regexp.escape(I18n.t("guide.procedure"))}/
            point = Guide::Procedure.site(cur_site).node(cur_node).where(id_name: id_name).first
          when /#{::Regexp.escape(I18n.t("guide.question"))}/
            point = Guide::Question.site(cur_site).node(cur_node).where(id_name: id_name).first
          end

          next unless point

          point_ids << point.id
          if type.match?(I18n.t("guide.labels.not_applicable"))
            not_applicable_point_ids << point.id
          end
          if type.match?(I18n.t("guide.labels.optional_necessary"))
            optional_necessary_point_ids << point.id
          end
        end
      end
      in_edges[idx][:point_ids] = point_ids
      in_edges[idx][:not_applicable_point_ids] = not_applicable_point_ids
      in_edges[idx][:optional_necessary_point_ids] = optional_necessary_point_ids
    end

    item.in_edges = in_edges
    if item.save
      true
    else
      message = item.errors.full_messages.join("\n")
      errors.add :base, "#{@row_index}: #{I18n.t("guide.errors.save_failed", message: message)}"
      false
    end
  end
end
