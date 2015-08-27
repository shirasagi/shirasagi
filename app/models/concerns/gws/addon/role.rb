module Gws::Addon
  module Role
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :gws_roles, class_name: "Gws::Role"
      permit_params gws_role_ids: []
    end
  end
end
