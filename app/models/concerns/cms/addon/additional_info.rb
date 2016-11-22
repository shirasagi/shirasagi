module Cms::Addon
  module AdditionalInfo
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :additional_info, type: Cms::Extensions::AdditionalInfo

      permit_params additional_info: [ :field, :value ]

      template_variable_handler /^add_info\.\S+$/, :template_variable_handler_add_info if respond_to?(:template_variable_handler)
    end

    def template_variable_handler_add_info(name, issuer)
      name =~ /^add_info\.(\S+)$/
      value_key = $1
      return if value_key.blank?

      h = additional_info.find { |h| h[:field] == value_key }
      return if h.blank?

      h[:value]
    end
  end
end
