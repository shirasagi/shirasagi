module Garbage::Addon
  module K5374::Center
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :rest_start, type: String
      field :rest_end, type: String

      permit_params :rest_start, :rest_end
    end
  end
end
