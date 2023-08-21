module Gws::Addon::Portal::Portlet
  module Presence
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      belongs_to :group, class_name: 'Gws::Group'
      belongs_to :custom_group, class_name: "Gws::CustomGroup"

      permit_params :group_id, :custom_group_id
    end
  end
end
