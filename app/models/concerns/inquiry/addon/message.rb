module Inquiry::Addon
  module Message
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :inquiry_html, type: String, default: ""
      field :inquiry_sent_html, type: String, default: ""
      field :inquiry_results_html, type: String, default: ""

      permit_params :inquiry_html, :inquiry_sent_html, :inquiry_results_html
    end
  end
end
