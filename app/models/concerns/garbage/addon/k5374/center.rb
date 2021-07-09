module Garbage::Addon
  module K5374::Center
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :rest_start, type: DateTime
      field :rest_end, type: DateTime
      permit_params :rest_start, :rest_end
    end
  end
end
