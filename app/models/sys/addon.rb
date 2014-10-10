module Sys::Addon
  module Role
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 600

    included do
      embeds_ids :sys_roles, class_name: "Sys::Role"
      permit_params sys_role_ids: []
    end
  end
end
