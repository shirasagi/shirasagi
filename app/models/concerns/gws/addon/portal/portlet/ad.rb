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
      options = {
        navigation: true, pagination: true, "pagination-clickable" => true
      }

      # 注意:
      # speed が未設定の場合、prev / next ナビゲーションが初回のみうまく動作し、2回目以降はうまく動作しない。
      # swiper の内部状態がアニメーション中のままとなるのが原因っぽい。
      # speed を設定すると、pause が未設定の場合、超高速でスライドが切り替わるようになってしまう。
      # そこで、speed と pause が未設定の場合、手動スライド切り替えモードとし、prev / next ナビゲーションを非表示とする。
      if ad_speed && ad_speed > 0 && ad_pause && ad_pause > 0
        options[:speed] = ad_speed
        options["autoplay-delay"] = ad_pause
        options["autoplay-disable-on-interaction"] = false
      end

      # a11y
      options["a11y-first-slide-message"] = I18n.t("ss.swiper_slide.first_slide_message")
      options["a11y-last-slide-message"] = I18n.t("ss.swiper_slide.last_slide_message")
      options["a11y-prev-slide-message"] = I18n.t("ss.swiper_slide.prev_slide_message")
      options["a11y-next-slide-message"] = I18n.t("ss.swiper_slide.next_slide_message")
      options["a11y-pagination-bullet-message"] = I18n.t("ss.swiper_slide.pagination_bullet_message")

      options
    end
  end
end
