module Guide::Addon
  module Question
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      attr_accessor :in_edges

      field :question_type, type: String, default: "yes_no"
      field :check_type, type: String, default: "multiple"

      embeds_many :edges, class_name: 'Guide::Diagram::Edge'
      embeds_ids :referenced_questions, class_name: 'Guide::Question'

      permit_params :question_type
      permit_params :check_type
      permit_params in_edges: [ :value, :question_type, point_ids: [] ]

      before_validation :set_check_type, if: ->{ question_type == "yes_no" }

      validates :question_type, presence: true
      validates :check_type, presence: true
      validate :validate_in_edges, if: ->{ in_edges.present? }

      after_save :set_referenced_questions
    end

    def question_type_options
      I18n.t("guide.options.question_type").map { |k, v| [v, k] }
    end

    def check_type_options
      I18n.t("guide.options.check_type").map { |k, v| [v, k] }
    end

    private

    def validate_in_edges
      with_type = in_edges.select { |in_edge| in_edge[:question_type] == question_type }
      with_type = with_type.each_with_index { |in_edge, i| in_edge[:transition] = (i + 1).to_s }

      # validate
      with_type.each_with_index do |in_edge, i|
        edge = ::Guide::Diagram::Edge.new(in_edge)
        next if edge.valid?

        edge.errors.full_messages.each do |msg|
          self.errors.add :base, "選択肢 #{i + 1} : #{msg}"
        end
      end
      return if errors.present?

      # set in_edges
      self.edges = with_type.map do |in_edge|
        self.edges.new(in_edge)
      end
    end

    def set_referenced_questions
      self.edges.each do |edge|
        edge.questions.each do |question|
          question.add_to_set(referenced_question_ids: id)
        end
      end
    end

    def set_check_type
      self.check_type = "single"
    end
  end
end
