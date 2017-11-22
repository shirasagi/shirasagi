module Gws::Addon::Portal::Portlet
  module Monitor
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet
  end
end
