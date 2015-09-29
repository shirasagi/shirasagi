module Faq::Addon
  module Question
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :question, type: String
      permit_params :question
    end
  end
end
