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
      ret = { pagination_style: "disc" }
      # ad_speed と ad_pause の両方が与えられると、自動スライド切り替えモード
      # ad_speed か ad_pause かのどちらかが省略されると、手動スライド切り替えモード
      #
      # 注意:
      # speed が未設定の場合、prev / next ナビゲーションが初回のみうまく動作し、2回目以降はうまく動作しない。
      # swiper の内部状態がアニメーション中のままとなるのが原因っぽい。
      # speed を設定すると、pause が未設定の場合、超高速でスライドが切り替わるようになってしまう。
      # そこで、speed と pause が未設定の場合、手動スライド切り替えモードとし、prev / next ナビゲーションを非表示とする。
      if ad_speed && ad_speed > 0 && ad_pause && ad_pause > 0
        ret[:autoplay] = "started"
        ret[:navigation] = "show"
        ret[:speed] = ad_speed
        ret[:pause] = ad_pause
      end
      ret
    end
  end
end
