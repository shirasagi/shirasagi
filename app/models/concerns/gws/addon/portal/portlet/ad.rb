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
      # 注意:
      # speed が未設定の場合、prev / next ナビゲーションが初回のみうまく動作し、2回目以降はうまく動作しない。
      # swiper の内部状態がアニメーション中のままとなるのが原因っぽい。
      # speed を設定すると、pause が未設定の場合、超高速でスライドが切り替わるようになってしまう。
      # そこで、speed と pause が未設定の場合、適切な初期値をセットしてやる。
      ret = { autoplay: "started", navigation: "show", pagination_style: "disc" }
      ret[:speed] = ad_speed && ad_speed > 0 ? ad_speed : Sys::Ad::DEFAULT_SLIDE_SPEED
      ret[:pause] = ad_pause && ad_pause > 0 ? ad_pause : Sys::Ad::DEFAULT_SLIDE_PAUSE
      ret
    end
  end
end
