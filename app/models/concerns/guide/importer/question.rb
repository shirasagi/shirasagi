module Guide::Importer::Question
  extend ActiveSupport::Concern

  def import_questions
    return false unless validate_import

    @row_index = 0
    self.class.each_csv(in_file) do |row|
      @row_index += 1
      @row = row
      save_question
    end

    errors.empty?
  end

  def questions_enum
    Enumerator.new do |y|
      headers = %w(id_name name explanation order question_type check_type).map { |v| Guide::Question.t(v) }
      edge_size = Guide::Question.site(cur_site).node(cur_node).map { |item| item.edges.size }.max
      if edge_size
        edge_size.times do |i|
          headers << "#{I18n.t("guide.transition")}#{i + 1}"
          headers << "#{I18n.t("guide.explanation")}#{i + 1}"
        end
      end

      y << encode_sjis(headers.to_csv)
      Guide::Question.site(cur_site).node(cur_node).each do |item|
        row = []
        row << item.id_name
        row << item.name
        row << item.explanation
        row << item.order
        row << item.label(:question_type)
        row << item.label(:check_type)
        item.edges.each do |edge|
          row << edge.value
          row << edge.explanation
        end
        y << encode_sjis(row.to_csv)
      end
    end
  end

  def save_question
    id_name = @row[Guide::Question.t(:id_name)]

    item = Guide::Question.site(cur_site).node(cur_node).where(id_name: id_name).first
    item ||= Guide::Question.new
    item.cur_site = cur_site
    item.cur_node = cur_node
    item.cur_user = cur_user
    item.id_name = id_name

    headers = %w(name explanation order)
    headers.each do |k|
      v = @row[Guide::Question.t(k)]
      item.send("#{k}=", v)
    end

    question_types = Guide::Question.new.question_type_options.to_h
    v = @row[Guide::Question.t(:question_type)]
    question_type = question_types[v].to_s
    item.question_type = question_type

    check_types = Guide::Question.new.check_type_options.to_h
    v = @row[Guide::Question.t(:check_type)]
    check_type = check_types[v].to_s
    item.check_type = check_type

    if item.invalid?
      message = item.errors.full_messages.join("\n")
      errors.add :base, "#{@row_index}: #{I18n.t("guide.errors.save_faild", message: message)}"
      return false
    end

    in_edges = []
    if question_type == "yes_no"

      # yes
      idx = 0
      in_edges[idx]||= begin
        edge = item.edges[idx]
        edge ? OpenStruct.new(point_ids: edge.point_ids) : OpenStruct.new
      end
      in_edges[idx][:question_type] = question_type
      in_edges[idx][:value] = I18n.t("guide.links.applicable")

      # no
      idx = 1
      in_edges[idx]||= begin
        edge = item.edges[idx]
        edge ? OpenStruct.new(point_ids: edge.point_ids) : OpenStruct.new
      end
      in_edges[idx][:question_type] = question_type
      in_edges[idx][:value] = I18n.t("guide.links.not_applicable")

    else

      # others
      edge_headers.each do |v, idx|
        v = @row[v]
        next if v.blank?

        in_edges[idx] ||= begin
          edge = item.edges[idx]
          edge ? OpenStruct.new(point_ids: edge.point_ids) : OpenStruct.new
        end
        in_edges[idx][:question_type] = question_type
        in_edges[idx][:value] = v
      end

      explanation_headers.each do |v, idx|
        v = @row[v]
        next if v.blank?

        in_edges[idx][:explanation] = v
      end
    end

    item.in_edges = in_edges
    if item.save
      true
    else
      message = item.errors.full_messages.join("\n")
      errors.add :base, "#{@row_index}: #{I18n.t("guide.errors.save_faild", message: message)}"
      false
    end
  end
end
