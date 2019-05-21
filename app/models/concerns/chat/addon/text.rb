module Chat::Addon
  module Text
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :first_text, type: String
      field :first_suggest, type: SS::Extensions::Words
      field :exception_text, type: String

      permit_params :first_text, :first_suggest, :exception_text
    end
  end
end
