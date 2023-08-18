module Cms::Addon
  module AdditionalInfo
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :additional_info, type: Cms::Extensions::AdditionalInfo

      permit_params additional_info: [ :field, :value ]
    end
  end
end
