module Garbage::Addon
  module K5374::Center
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :rest_start, type: DateTime
      field :rest_end, type: DateTime
      permit_params :rest_start, :rest_end

      template_variable_handler(:rest_start, :template_variable_handler_name)
      template_variable_handler(:rest_end, :template_variable_handler_name)

      liquidize do
        export :rest_start
        export :rest_end
      end
    end
  end
end
