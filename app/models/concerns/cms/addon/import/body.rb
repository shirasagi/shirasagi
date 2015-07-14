module Cms::Addon::Import
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String, metadata: { form: :text }
      permit_params :html
    end
  end
end
