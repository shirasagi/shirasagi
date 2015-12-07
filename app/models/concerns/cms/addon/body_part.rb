module Cms::Addon
  module BodyPart
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :body_parts, type: Array, default: []
      permit_params body_parts: []
    end
  end
end
