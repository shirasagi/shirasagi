module Garbage::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :remark, type: String
      field :kana, type: String
      permit_params :name, :remark, :kana

      template_variable_handler(:remark, :template_variable_handler_name)
      template_variable_handler(:kana, :template_variable_handler_name)

      liquidize do
        export :remark
        export :kana
      end
    end
  end
end
