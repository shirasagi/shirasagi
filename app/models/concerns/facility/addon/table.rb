module Facility::Addon
  module Table
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :facility_caption, type: String

      permit_params :facility_caption
    end

    def caption_name
      facility_caption || name
    end
  end
end
