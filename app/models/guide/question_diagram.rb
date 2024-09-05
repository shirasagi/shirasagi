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
    @procedure_necessary_count = {}
    @procedure_optional_necessary_count = {}
    @questions = []

    @queue = []
    @longest_length = @roots.sum { |point| calc_longest_length(point) }
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
          next_points = point.applicable_transitions[key].to_a
        else
          next_points = point.not_applicable_transitions[key].to_a
        end

        next if next_points.blank?

        next_points = next_points.map do |next_point|
          if next_point.question?
            if @referenced_questions.include?(next_point)
              nil
            else
              @referenced_questions << next_point
              next_point
            end
          else
            @procedure_necessary_count[next_point.id] ||= 0
            @procedure_optional_necessary_count[next_point.id] ||= 0
            if point.necessary_transitions[key].present? && point.necessary_transitions[key].to_a.include?(next_point)
              @procedure_necessary_count[next_point.id] += 1
            end
            if point.optional_necessary_transitions[key].present? &&
               point.optional_necessary_transitions[key].to_a.include?(next_point)
              @procedure_optional_necessary_count[next_point.id] += 1
            end
            if (next_point.necessary_count.zero? || next_point.necessary_count <= @procedure_necessary_count[next_point.id]) &&
               (next_point.optional_necessary_count.zero? || @procedure_optional_necessary_count[next_point.id] > 0)
              @procedures[next_point.id] = next_point
            end
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
    @procedures.values.sort_by { |item| item.order.to_i }
  end

  def all_procedures
    @all_procedures.values.sort_by { |item| item.order.to_i }
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
    point.applicable_transitions = {}
    point.not_applicable_transitions = {}
    point.necessary_transitions = {}
    point.optional_necessary_transitions = {}

    if point.question?
      point.edges.each do |edge|
        point.transitions[edge.transition] = []
        point.applicable_transitions[edge.transition] = []
        point.not_applicable_transitions[edge.transition] = []
        point.necessary_transitions[edge.transition] = []
        point.optional_necessary_transitions[edge.transition] = []
        edge.points.each do |next_point|
          point.transitions[edge.transition] << build_diagram(next_point)
        end
        edge.applicable_points.each do |next_point|
          point.applicable_transitions[edge.transition] << build_diagram(next_point)
        end
        edge.not_applicable_points.each do |next_point|
          point.not_applicable_transitions[edge.transition] << build_diagram(next_point)
        end
        edge.necessary_points.each do |next_point|
          point.necessary_transitions[edge.transition] << build_diagram(next_point)
        end
        edge.optional_necessary_points.each do |next_point|
          point.optional_necessary_transitions[edge.transition] << build_diagram(next_point)
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
