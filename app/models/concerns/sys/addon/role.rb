module Sys::Addon
  module Role
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :sys_roles, class_name: "Sys::Role"
      permit_params sys_role_ids: []
    end
  end
end
