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
        %w(プルダウン select),
        %w(チェックボックス checkbox)
      ]
    end

    def required_options
      [
        %w(必須 required),
        %w(任意 optional)
      ]
    end

    def required?
      required == "required"
    end
  end
end
