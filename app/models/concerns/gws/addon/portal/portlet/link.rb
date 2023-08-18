module Gws::Addon::Portal::Portlet
  module Link
    extend ActiveSupport::Concern
    extend SS::Addon
    include Gws::Addon::Link::Feature

    set_addon_type :gws_portlet

    included do
      validate :validate_links, if: ->{ portlet_model == 'links' }
    end
  end
end
