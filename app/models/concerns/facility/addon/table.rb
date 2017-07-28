module Facility::Addon
  module Table
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :caption, type: String

      permit_params :caption
    end

    def caption_name
      caption || name
    end
  end
end
