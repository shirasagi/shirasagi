module Gws::Addon::Portal::Portlet
  module Ad
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :ad_width, type: Integer
      field :ad_speed, type: Integer
      field :ad_pause, type: Integer
      permit_params :ad_width, :ad_speed, :ad_pause
    end

    def effective_ad_width
      ad_width.present? && ad_width > 0 ? ad_width : 600
    end

    def ad_options
      ret = { auto: true, slideWidth: effective_ad_width, mode: 'horizontal', touchEnabled: false }
      ret[:speed] = ad_speed if ad_speed.present?
      ret[:pause] = ad_pause if ad_pause.present?
      ret
    end
  end
end
