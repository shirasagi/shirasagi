module Garbage::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :name, type: String
      field :remark, type: String

      permit_params :name, :remark

      template_variable_handler(:garbage, :template_variable_handler_garbage)
      template_variable_handler(:garbage_category, :template_variable_handler_garbage_category)
      template_variable_handler(:garbage_remark, :template_variable_handler_garbage_remark)
    end

    def template_variable_handler_garbage(name, issuer)
      ERB::Util.html_escape self.send(:name)
    end

    def template_variable_handler_garbage_category(name, issuer)
      ERB::Util.html_escape self.categories.map(&:name).join("\n")
    end

    def template_variable_handler_garbage_remark(name, issuer)
      ERB::Util.html_escape self.send(:remark)
    end
  end
end
