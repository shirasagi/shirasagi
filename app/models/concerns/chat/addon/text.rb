module Chat::Addon
  module Text
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :first_text, type: String
      field :first_suggest, type: SS::Extensions::Words
      field :exception_text, type: String
      field :response_template, type: String
      field :question, type: String
      field :chat_success, type: String
      field :chat_retry, type: String
      field :facility_search, type: String

      has_many :intents, class_name: "Chat::Intent", order: :order.asc, dependent: :destroy
      has_many :chat_categories, class_name: "Chat::Category", order: :order.asc, dependent: :destroy
      has_many :histories, class_name: "Chat::History", dependent: :destroy

      permit_params :first_text, :first_suggest, :exception_text, :response_template, :question, :chat_success, :chat_retry, :facility_search
    end
  end
end