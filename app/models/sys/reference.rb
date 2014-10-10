module Sys::Reference

  module Role
    extend ActiveSupport::Concern

    included do
      embeds_ids :sys_roles, class_name: "Sys::Role"
      permit_params cms_role_ids: []
    end
  end

end
