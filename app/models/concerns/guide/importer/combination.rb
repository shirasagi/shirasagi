module Guide::Importer::Combination
  extend ActiveSupport::Concern

  def combinations_enum
    Enumerator.new do |y|
      headers = [I18n.t("guide.procedure")] # 手続き
      y << encode_sjis(headers.to_csv)

      headers = ['']
      headers += %w(
        id_name name link_url order html procedure_location belongings procedure_applicant remarks
      ).map { |v| Guide::Procedure.t(v) }

      y << encode_sjis(headers.to_csv)

      Guide::Procedure.site(cur_site).node(cur_node).each do |item|
        row = ['']
        row << item.id_name
        row << item.name
        row << item.link_url
        row << item.order
        row << item.html
        row << item.procedure_location
        row << item.belongings
        row << item.procedure_applicant
        row << item.remarks
        y << encode_sjis(row.to_csv)
      end

      headers = [I18n.t("guide.question")] # 質問
      y << encode_sjis(headers.to_csv)

      headers = ['']
      headers += %w(id_name name explanation order question_type check_type).map { |v| Guide::Question.t(v) }
      headers << I18n.t("guide.transition")
      headers << I18n.t("guide.explanation")
      headers << I18n.t("guide.transition_settings")
      y << encode_sjis(headers.to_csv)

      Guide::Question.site(cur_site).node(cur_node).each do |item|
        row = ['']
        row << item.id_name
        row << item.name
        row << item.explanation
        row << item.order
        row << item.label(:question_type)
        row << item.label(:check_type)
        y << encode_sjis(row.to_csv)

        item.edges.to_a.each do |edge|
          row = ['']
          row = [''].cycle.take(7)
          row << edge.value
          row << edge.explanation

          edge_list = edge.points.map do |point|
            value = point.name_with_type
            # applicable or not_applicable
            label = edge.not_applicable_point_ids.include?(point.id) ? I18n.t('guide.labels.not_applicable') : nil
            value =  value.sub('] ', "][#{label}] ") if label
            # necessary or optional_necessary
            label = edge.optional_necessary_point_ids.include?(point.id) ? I18n.t('guide.labels.optional_necessary') : nil
            value =  value.sub('] ', "][#{label}] ") if label
            value
          end
          row << edge_list.join("\n")

          y << encode_sjis(row.to_csv)
        end
      end
    end
  end

  def import_combinations
    return false unless validate_import

    @row_index = 1
    self.class.each_csv(in_file) do |row, index|
      @row_index += 1
      next if @row_index <= 2
      @row = row
      break if save_combination_procedure == false
    end
    return false if errors.present?

    question_index = nil
    @questions = []

    @row_index = 1
    self.class.each_csv(in_file) do |row, index|
      @row_index += 1
      next if row[0] != I18n.t("guide.question")
      question_index = @row_index + 1
      break
    end

    if question_index
      @row_index = 1
      self.class.each_csv(in_file) do |row, index|
        @row_index += 1
        next if @row_index <= question_index
        @row = row
        break if save_combination_question == false
      end
    end
    return false if errors.present?

    @questions.each do |item|
      break if save_combination_question_edges(item) == false
    end

    errors.empty?
  end

  # 手続き
  def save_combination_procedure
    return false if @row.to_s.blank?
    return false if @row[0].present?

    id_name = @row[1]

    item = Guide::Procedure.site(cur_site).node(cur_node).where(id_name: id_name).first
    item ||= Guide::Procedure.new
    item.cur_site = cur_site
    item.cur_node = cur_node
    item.cur_user = cur_user
    item.id_name = id_name
    item.name = @row[2]
    item.link_url = @row[3]
    item.order = @row[4]
    item.html = @row[5]
    item.procedure_location = @row[6]
    item.belongings = @row[7]
    item.procedure_applicant = @row[8]
    item.remarks= @row[9]

    if item.save
      true
    else
      message = item.errors.full_messages.join("\n")
      errors.add :base, "Line #{@row_index}: #{I18n.t("guide.errors.save_failed", message: message)}"
      false
    end
  end

  # 質問
  def save_combination_question
    return false if @row.to_s.blank?
    return false if @row[0].present?

    id_name = @row[1]

    if @row[1].present? # 基本情報
      question_types = Guide::Question.new.question_type_options.to_h
      check_types = Guide::Question.new.check_type_options.to_h

      item = Guide::Question.site(cur_site).node(cur_node).where(id_name: id_name).first
      item ||= Guide::Question.new
      item.cur_site = cur_site
      item.cur_node = cur_node
      item.cur_user = cur_user
      item.id_name = id_name
      item.name = @row[2]
      item.explanation = @row[3]
      item.order = @row[4]
      item.question_type = question_types[@row[5]].to_s
      item.check_type = check_types[@row[6]].to_s

      item.row_index = @row_index
      item.tmp_edges = []
      @questions << item

      if item.save
        true
      else
        message = item.errors.full_messages.join("\n")
        errors.add :base, "Line #{@row_index}: #{I18n.t("guide.errors.save_failed", message: message)}"
        false
      end

    elsif @row[7].present? # 選択肢
      item = @questions.last
      return true unless item

      item.tmp_edges ||= []
      item.tmp_edges << {
        value: @row[7],
        question_type: item.question_type,
        explanation: @row[8],
        point_ids: [],
        not_applicable_point_ids: [],
        optional_necessary_point_ids: [],
        point_names: @row[9].to_s.strip.split("\n")
      }
      return true
    end
  end

  def save_combination_question_edges(item)
    label_question = I18n.t('guide.question')
    label_procedure = I18n.t('guide.procedure')
    label_not_applicable = I18n.t('guide.labels.not_applicable')
    label_optional_necessary = I18n.t('guide.labels.optional_necessary')

    item.in_edges = item.tmp_edges.to_a.map do |edge|
      # 非該当, 任意必要
      edge[:point_names].to_a.each do |line|
        cate, name = line.split(/ /, 2)
        rel = nil

        if cate.match(label_procedure)
          rel = Guide::Procedure.site(cur_site).node(cur_node).where(id_name: name).first
          edge[:point_ids] << rel.id if rel
          item.errors.add :base, I18n.t('guide.errors.not_found_procedure', id: name)  unless rel
        elsif cate.match(label_question)
          rel = Guide::Question.site(cur_site).node(cur_node).where(id_name: name).first
          edge[:point_ids] << rel.id if rel
          item.errors.add :base, I18n.t('guide.errors.not_found_question', id: name)  unless rel
        end
        if rel && cate.match(label_not_applicable)
          edge[:not_applicable_point_ids] << rel.id
        end
        if rel && cate.match(label_optional_necessary)
          edge[:optional_necessary_point_ids] << rel.id
        end
      end

      edge.delete(:point_names)
      edge
    end

    if item.errors.empty?
      item.save
    else
      message = item.errors.full_messages.uniq.join("\n")
      errors.add :base, "Line #{item.row_index}: #{I18n.t("guide.errors.save_failed", message: message)}"
      false
    end
  end
end
