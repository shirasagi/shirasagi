module Cms::Addon
  module Role
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :cms_roles, class_name: "Cms::Role"
      permit_params cms_role_ids: []
    end
  end
end
