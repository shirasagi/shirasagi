module Garbage::Addon
  module K5374::Description
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :style, type: String
      field :bgcolor, type: String

      permit_params :style, :bgcolor

      validates :bgcolor, "ss/color" => true
    end
  end
end
