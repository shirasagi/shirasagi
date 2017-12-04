module Gws::Addon::Portal::Portlet
  module Free
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :html, type: String
      permit_params :html
    end
  end
end
