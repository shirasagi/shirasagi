module Garbage::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :name, type: String
      field :remark, type: String

      permit_params :name, :remark

      template_variable_handler(:remark, :template_variable_handler_name)

      liquidize do
        export :remark
      end
    end
  end
end
