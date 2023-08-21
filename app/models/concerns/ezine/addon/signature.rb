module Ezine::Addon
  module Signature
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :signature_html, type: String, default: ""
      field :signature_text, type: String, default: ""
      permit_params :signature_html, :signature_text
    end
  end
end
