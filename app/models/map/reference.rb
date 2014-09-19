# coding: utf-8
module Map::Reference

=begin
  module Question
    extend ActiveSupport::Concern

    included do
      field :question, type: String, metadata: { form: :text }
      permit_params :question
    end
  end
=end
end
