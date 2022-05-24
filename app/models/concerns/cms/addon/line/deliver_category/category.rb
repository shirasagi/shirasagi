module Cms::Addon
  module Line::DeliverCategory::Category
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :select_type, type: String, default: "select"
      field :required, type: String, default: "required"
      permit_params :select_type, :required
    end

    def select_type_options
      [
        %(プルダウン select),
        %(チェックボックス checkbox)
      ]
    end

    def required_options
      [
        %(必須 required),
        %(任意 optional)
      ]
    end

    def required?
      required == "required"
    end
  end
end
