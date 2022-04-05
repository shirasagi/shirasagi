class Guide::QuestionDiagram
  attr_reader :node, :roots, :longest_length, :shortest_length, :questions, :unevaluated_longest_length

  def initialize(node)
    @node = node
    @all_procedures = {}
    @referenced_questions = Guide::Question.node(node).
      entries.
      select { |point| point.referenced_questions.blank? }
    @roots = @referenced_questions.map { |point| build_diagram(point) }

    @procedures = {}
    @questions = []

    @queue = []
    @longest_length = @roots.sum { |point| calc_longest_length(point) }
    @queue = []
    @shortest_length = @roots.sum { |point| calc_shortest_length(point) }
    @unevaluated_longest_length = @longest_length
  end

  def input_answers(answers)
    @procedures = {}
    @questions = []

    points = @roots.dup
    answers.each do |answer|
      point = points.shift
      break if points.nil?

      @questions << point

      transitions = answer.is_a?(Array) ? answer : [answer]
      point.transitions.each do |key, _|
        if transitions.include?(key)
          next_points = point.positive_transitions[key].to_a
        else
          next_points = point.negative_transitions[key].to_a
        end

        next if next_points.blank?

        next_points = next_points.map do |point|
          if point.question?
            if @referenced_questions.include?(point)
              nil
            else
              @referenced_questions << point
              point
            end
          else
            @procedures[point.id] = point
            nil
          end
        end.compact

        points = next_points + points if next_points.present?
      end
    end

    @queue = []
    @unevaluated_longest_length = points.sum { |point| calc_longest_length(point) }

    points
  end

  def procedures
    @procedures.values.sort_by { |item| item.order }
  end

  def all_procedures
    @all_procedures.values.sort_by { |item| item.order }
  end

  def evaluated_length
    @longest_length - @unevaluated_longest_length
  end

  def progress
    (evaluated_length.to_f / @longest_length).floor(2)
  end

  private

  def build_diagram(point)
    point.transitions = {}
    point.positive_transitions = {}
    point.negative_transitions = {}

    if point.question?
      point.edges.each do |edge|
        point.transitions[edge.transition] = []
        point.positive_transitions[edge.transition] = []
        point.negative_transitions[edge.transition] = []
        edge.points.each do |next_point|
          point.transitions[edge.transition] << build_diagram(next_point)
        end
        edge.positive_points.each do |next_point|
          point.positive_transitions[edge.transition] << build_diagram(next_point)
        end
        edge.negative_points.each do |next_point|
          point.negative_transitions[edge.transition] << build_diagram(next_point)
        end
      end
    else
      @all_procedures[point.id] = point
    end
    point
  end

  def calc_longest_length(point)
    if point.question?
      @queue << point.id
      lengths = []

      point.transitions.each do |transition, next_points|
        length = 0
        next_points.each do |next_point|
          next if @queue.include?(next_point.id)
          length += calc_longest_length(next_point)
        end
        lengths << length
      end

      if point.question_type == "choices" && point.check_type == "multiple"
        length = lengths.sum.to_i + 1
      else
        length = lengths.max.to_i + 1
      end

      length
    else
      0
    end
  end

  def calc_shortest_length(point)
    if point.question?
      @queue << point.id
      lengths = []

      point.transitions.each do |transition, next_points|
        length = 0
        next_points.each do |next_point|
          next if @queue.include?(next_point.id)
          length += calc_shortest_length(next_point)
        end
        lengths << length
      end

      if point.question_type == "choices" && point.check_type == "multiple"
        length = 1
      else
        length = lengths.min.to_i + 1
      end

      length
    else
      0
    end
  end
end
