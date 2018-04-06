module Garbage::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :name, type: String
      field :remark, type: String

      permit_params :name, :remark
    end
  end

  module AdditionalInfo
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :additional_info, type: Garbage::Extensions::AdditionalInfo

      permit_params additional_info: [ :field, :value ]
    end
  end
end
