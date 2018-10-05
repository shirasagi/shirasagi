module Gws::Addon::Portal::Portlet
  module Ad
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      include Gws::Addon::File
      field :state, type: String
      field :time, type: Integer
      permit_params :state, :time
      validate :validate_files_limit
    end

    def validate_files_limit
      limit = SS.config.gws.portal["portlet_settings"]["ad"]["image_limit"]
      if files.size > limit
        errors.add :files, :too_many_files, limit: limit
      end
    end
  end
end
