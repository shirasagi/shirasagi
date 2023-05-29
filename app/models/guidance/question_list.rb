class Guidance::QuestionList
  extend SS::Translation

  attr_accessor :node, :questions

  def initialize(node)
    @node = node
    @questions = node.guidance_questions.map { |c| Guidance::Question.new(c) }
  end

  def each
    @questions.each do |question|
      yield question
    end
  end

  def group_by_question_key
    items = {}

    self.each do |question|
      items[question.question_key] ||= [question, []]
      items[question.question_key][1] << question
    end

    items.values
  end

  def to_hash_list
    group_by_question_key.map do |question, question_items|
      [question.to_question_hash, question_items.map(&:to_question_item_hash)]
    end
  end

  def encode_sjis(str)
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def csv_headers
    %w(
      question_key question_type question_item
      condition_and condition_or1 condition_or2 condition_or3
    ).map { |v| Guidance::Question.t(v) }
  end

  def enum_csv
    Enumerator.new do |y|
      y << encode_sjis(csv_headers.to_csv)
      self.each do |item|
        line = []
        line << item.question_key
        line << item.label(:question_type)
        line << item.question_item
        line << item.condition_and.join("\n")
        line << item.condition_or1.join("\n")
        line << item.condition_or2.join("\n")
        line << item.condition_or3.join("\n")
        y << encode_sjis(line.to_csv)
      end
    end
  end
end
