module Cms::Addon
  module Html
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String, metadata: { form: :text }
      permit_params :html
    end
  end
end
