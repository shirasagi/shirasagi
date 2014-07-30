# coding: utf-8
module Faq::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

    included do
      field :question_html, type: String, metadata: { form: :text }
      field :answer_html, type: String, metadata: { form: :text }
      permit_params :question_html, :answer_html
    end
  end

end
