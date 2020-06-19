class Guide::QuestionDiagram
  attr_reader :node

  attr_reader :roots
  attr_reader :longest_length
  attr_reader :shortest_length

  attr_reader :questions
  attr_reader :unevaluated_longest_length

  def initialize(node)
    @node = node
    @all_procedures = {}
    @roots = Guide::Question.node(node).
      select { |point| point.referenced_questions.blank? }.
      map { |point| build_diagram(point) }

    @procedures = {}
    @questions = []

    @longest_length = @roots.map { |point| calc_longest_length(point) }.sum
    @shortest_length = @roots.map { |point| calc_shortest_length(point) }.sum
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

      transitions = answer.kind_of?(Array) ? answer : [answer]
      transitions.each do |transition|
        next_points = point.transitions[transition].to_a

        next_points = next_points.map do |point|
          if point.question?
            point
          else
            @procedures[point.id] = point
            nil
          end
        end.compact

        points = next_points + points if next_points.present?
      end
    end

    @unevaluated_longest_length = points.map { |point| calc_longest_length(point) }.sum

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
    (evaluated_length.to_f / @longest_length.to_f).floor(2)
  end

  private

  def build_diagram(point)
    point.transitions = {}

    if point.question?
      point.edges.each do |edge|
        point.transitions[edge.transition] = []
        edge.points.each do |next_point|
          point.transitions[edge.transition] << build_diagram(next_point)
        end
      end
      point
    else
      @all_procedures[point.id] = point
      point
    end
  end

  def calc_longest_length(point)
    if point.question?
      lengths = []

      point.transitions.each do |transition, next_points|
        length = 0
        next_points.each do |next_point|
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
      lengths = []

      point.transitions.each do |transition, next_points|
        length = 0
        next_points.each do |next_point|
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

  #def transitions
  #  @roots.each do |point|
  #    transitions_(point, 1)
  #  end
  #end

  #def transitions_(point, depth)
  #  if point.transitions.keys.present?
  #    puts "#{"-" * depth}#{point.transitions.keys.join(", ")}"
  #  end
  #
  #  point.transitions.each do |key, next_points|
  #    next_points.each do |next_point|
  #      transitions_(next_point, depth + 1)
  #    end
  #  end
  #end
end
