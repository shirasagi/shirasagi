module Ezine::Addon
  module Body
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :html, type: String, default: ""
      field :text, type: String, default: ""
      permit_params :html, :text
    end
  end
end
