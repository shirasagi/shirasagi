class Guide::QuestionDiagram
  attr_reader :node, :roots, :longest_length, :shortest_length, :questions, :unevaluated_longest_length

  def initialize(node)
    @node = node
    @all_build_points = {}
    @all_procedures = {}
    @roots = Guide::Question.node(node).
      select { |point| point.referenced_questions.blank? }.
      map { |point| build_diagram(point) }

    @evaluated = {}
    @procedures = {}
    @questions = []

    @longest_length = @roots.sum { |point| calc_longest_length(point) }
    @shortest_length = @roots.sum { |point| calc_shortest_length(point) }
    @unevaluated_longest_length = @longest_length
  end

  def input_answers(answers)
    @evaluated = {}
    @procedures = {}
    @questions = []

    points = @roots.dup
    answers.each do |answer|
      point = points.shift
      break if points.nil?

      @questions << point

      transitions = answer.is_a?(Array) ? answer : [answer]
      transitions.each do |transition|
        next_points = []
        point.transitions[transition].to_a.each do |point|
          if point.question? && @evaluated[point.id].nil?
            next_points << point
            @evaluated[point.id] = point
          end
          if point.procedure?
            @procedures[point.id] = point
          end
        end
        points = next_points + points if next_points.present?
      end
    end

    @unevaluated_longest_length = points.sum { |point| calc_longest_length(point) }

    points
  end

  def procedures
    @procedures.values.sort_by { |item| item.order.to_i }
  end

  def all_procedures
    @all_procedures.values.sort_by { |item| item.order.to_i }
  end

  def evaluated_length
    @longest_length - @unevaluated_longest_length
  end

  def progress
    (evaluated_length.to_f / @longest_length.to_f).floor(2)
  end

  private

  def build_diagram(point)
    if @all_build_points[point.id]
      return @all_build_points[point.id]
    end

    point.transitions = {}
    if point.question?
      point.edges.each do |edge|
        point.transitions[edge.transition] = []
        edge.points.each do |next_point|
          point.transitions[edge.transition] << build_diagram(next_point)
        end
      end
    else
      @all_procedures[point.id] = point
    end

    @all_build_points[point.id] = point
    point
  end

  def calc_longest_length(point)
    if point.question?
      if point.question_type == "choices" && point.check_type == "multiple"
        # 複数選択の場合は全ての遷移を結合して、各遷移のコストを合計する
        multiple_points = {}
        point.transitions.each do |transition, next_points|
          next_points.each do |next_point|
            multiple_points[next_point.id] = next_point
          end
        end

        length = 0
        multiple_points.each do |_, next_point|
          length += calc_longest_length(next_point)
        end
        length + 1
      else
        # 単数選択の場合は全ての遷移の中から最も大きいもの選ぶ
        lengths = []
        point.transitions.each do |transition, next_points|
          length = 0
          next_points.each do |next_point|
            length += calc_longest_length(next_point)
          end
          lengths << length
        end
        lengths.max.to_i + 1
      end
    else
      0
    end
  end

  def calc_shortest_length(point)
    if point.question?
      lengths = []

      point.transitions.each do |transition, next_points|
        length = 0
        next_points.each do |next_point|
          length += calc_shortest_length(next_point)
        end
        lengths << length
      end

      if point.question_type == "choices" && point.check_type == "multiple"
        # 複数選択の場合は何も選ばない（コスト1が最小）
        length = 1
      else
        # 単数選択の場合は全ての遷移の中から最も小さいもの選ぶ
        length = lengths.min.to_i + 1
      end

      length
    else
      0
    end
  end
end
