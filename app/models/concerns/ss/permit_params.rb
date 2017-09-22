module SS::PermitParams
  extend ActiveSupport::Concern

  included do
    class_variable_set(:@@_permit_params, [])
  end

  module ClassMethods
    def permitted_fields
      class_variable_get(:@@_permit_params)
    end

    def permit_params(*fields)
      params = class_variable_get(:@@_permit_params)
      class_variable_set(:@@_permit_params, params + fields)
    end
  end
end
