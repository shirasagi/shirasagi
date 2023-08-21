module SS::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String
      permit_params :html
    end
  end
end
