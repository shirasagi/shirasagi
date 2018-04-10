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
end
