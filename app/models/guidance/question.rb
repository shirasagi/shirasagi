class Guidance::Question
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User
  include Guidance::ConditionFields

  attr_accessor :in_file

  field :question_key, type: String
  field :question_type, type: String
  field :question_item, type: String

  permit_params :in_file

  def save
    false
  end

  def question_type_options
    %w(single multiple yes_no).map { |m| [I18n.t("guidance.options.question_type.#{m}"), m] }
  end

  def decode_label(field, label)
    send("#{field}_options").find { |v, _| v == label }.try(:[], 1)
  end

  def question_name
    question_key.sub(/\d+\z/, '')
  end

  def to_question_hash
    {
      question_key: question_key,
      question_name: question_name,
      question_type: question_type
    }
  end

  def to_question_item_hash
    {
      question_item: question_item,
      condition_and: complement_condition_and.to_a,
      condition_or1: complement_condition_or1.to_a,
      condition_or2: complement_condition_or2.to_a,
      condition_or3: complement_condition_or3.to_a,
    }
  end

  def import_csv(node)
    validate_import_file
    return false unless errors.empty?

    data = []
    each_csv do |row, no|
      no += 1

      data << {
        question_key: row[t(:question_key)],
        question_type: decode_label(:question_type, row[t(:question_type)]),
        question_item: row[t(:question_item)],
        condition_and: row[t(:condition_and)].to_s.split("\n"),
        condition_or1: row[t(:condition_or1)].to_s.split("\n"),
        condition_or2: row[t(:condition_or2)].to_s.split("\n"),
        condition_or3: row[t(:condition_or3)].to_s.split("\n"),
      }

      # item.save
      # SS::Model.copy_errors(item, self, prefix: "##{no} ") if item.errors.present?
    end

    node.guidance_questions = data
    node.save
  end

  private

  def each_csv(&block)
    SS::Csv.foreach_row(in_file, headers: true, &block)
  end

  def validate_import_file
    return errors.add :in_file, :blank if in_file.blank?

    fname = in_file.original_filename
    unless /^\.csv$/i.match?(::File.extname(fname))
      errors.add :in_file, :invalid_file_type
      return
    end

    begin
      each_csv do |row, no|
        no += 1
        # check csv record up to 100
        break if no >= 100
      end
      in_file.rewind
    rescue => e
      errors.add :in_file, :invalid_file_type
    end
  end
end
