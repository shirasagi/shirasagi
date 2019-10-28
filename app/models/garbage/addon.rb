module Garbage::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :name, type: String
      field :remark, type: String

      permit_params :name, :remark

      template_variable_handler(:remark, :template_variable_handler_name)
      template_variable_handler(:categories, :template_variable_handler_categories)
    end

    def template_variable_handler_categories(name, issuer)
      ERB::Util.html_escape self.categories.map(&:name).join("\n")
    end
  end
end
