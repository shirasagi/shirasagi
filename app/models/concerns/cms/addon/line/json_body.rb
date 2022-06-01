module Cms::Addon
  module Line::JsonBody
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      field :json_body, type: String
      permit_params :json_body
      validate :validate_json_body
    end

    def body
      ::JSON.parse(json_body)
    end

    private

    def validate_json_body
      if json_body.blank?
        errors.add :json_body, :blank
        return
      end

      begin
        body
      rescue JSON::ParserError => e
        errors.add :json_body, :invalid
      end
    end
  end
end
