module Faq::Addon
  module Question
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :question, type: String, metadata: { form: :text }
      permit_params :question
    end
  end
end
