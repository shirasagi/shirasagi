module Faq::Addon
  module Question
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :question, type: String
      permit_params :question
    end

    def html_bytesize
      super + question.to_s.bytesize
    end
  end
end
