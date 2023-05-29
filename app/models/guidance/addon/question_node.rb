module Guidance::Addon
  module QuestionNode
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_guidance_questions

      field :guidance_questions, type: Array, default: []

      permit_params :in_guidance_questions
    end

    def guidance_results
      Guidance::Result.site(site).node(self)
    end

    def guidance_question_list
      Guidance::QuestionList.new(self)
    end
  end
end
