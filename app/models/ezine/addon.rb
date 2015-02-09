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

  module SenderAddress
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 410

    included do
      field :sender_name, type: String, default: ""
      field :sender_email, type: String, default: ""
      permit_params :sender_name, :sender_email
    end
  end

  module Reply
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 420

    included do
      field :reply_upper_text, type: String, default: ""
      field :reply_lower_text, type: String, default: ""
      permit_params :reply_upper_text, :reply_lower_text
    end
  end
end
