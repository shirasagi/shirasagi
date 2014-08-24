# coding: utf-8
module Faq::Addon
  module Question
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

    included do
      field :question, type: String, metadata: { form: :text }
      permit_params :question
    end
  end

end
