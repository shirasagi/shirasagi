module Cms::Addon
  module Line::Service::Hub
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :expired_text, type: String
      field :expired_minutes, type: Integer, default: 10
      permit_params :expired_text, :expired_minutes
    end
  end
end
