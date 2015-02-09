module Ezine::Addon
  module Page
    module Body
      extend SS::Addon
      extend ActiveSupport::Concern

      set_order 300

      included do
        field :html, type: String, default: ""
        field :text, type: String, default: ""
        permit_params :html, :text
      end
    end
  end

  module Signature
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 400

    included do
      field :signature_html, type: String, default: ""
      field :signature_text, type: String, default: ""
      permit_params :signature_html, :signature_text
    end
  end
end
