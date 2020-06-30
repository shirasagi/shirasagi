module Garbage::Addon
  module Description
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :style, type: String
      field :bgcolor, type: String

      permit_params :style, :bgcolor
    end
  end
end