module Chat::Addon
  module Path
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :chat_path, type: String

      permit_params :chat_path
    end
  end
end
