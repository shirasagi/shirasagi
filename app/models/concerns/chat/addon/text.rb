module Chat::Addon
  module Text
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :first_text, type: String
      field :first_suggest, type: SS::Extensions::Words
      field :exception_text, type: String

      has_many :intents, class_name: "Chat::Intent", order: :order.asc, dependent: :destroy
      has_many :chat_categories, class_name: "Chat::Category", order: :order.asc, dependent: :destroy

      permit_params :first_text, :first_suggest, :exception_text, :intent_id

      before_destroy :destroy_intents
    end

    private

    def destroy_intents
      intents.destroy
    end
  end
end
