module Guide2::QuestionList
  extend ActiveSupport::Concern
  #extend SS::Translation

  included do
    field :guide2_questions_hash, type: String
    field :guide2_results_hash, type: String
    embeds_many :guide2_questions, class_name: 'Guide2::Question'
    embeds_many :guide2_results, class_name: 'Guide2::Result'

    before_save :guide2_set_questions_hash
    before_save :guide2_set_results_hash
  end

  def guide2_condition_options
    %w(YES OR NO).map { |v| [I18n.t("guide2.options.condition.#{v}"), v] }
  end

  def guide2_build_questions_hash
    hash = guide2_questions.map do |data|
      data.attributes.reject{|k, v| %w(created updated).include?(k) }
    end
    Digest::MD5.hexdigest(hash.to_s)
  end

  def guide2_build_results_hash
    hash = guide2_results.map do |data|
      data.attributes.reject{|k, v| %w(created updated).include?(k) }
    end
    Digest::MD5.hexdigest(hash.to_s)
  end

  def guide2_total_hash
    Digest::MD5.hexdigest("#{guide2_questions_hash}#{guide2_results_hash}")
  end

  private

  def guide2_set_questions_hash
    self.guide2_questions_hash = guide2_build_questions_hash
  end

  def guide2_set_results_hash
    self.guide2_results_hash = guide2_build_results_hash
  end
end
