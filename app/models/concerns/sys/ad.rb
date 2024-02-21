module Sys::Ad
  extend ActiveSupport::Concern
  extend SS::Translation

  DEFAULT_SLIDE_WIDTH = 360
  DEFAULT_SLIDE_SPEED = 500
  DEFAULT_SLIDE_PAUSE = 5000

  included do
    include SS::Addon::LinkFile
    field :time, type: Integer
    field :width, type: Integer
    permit_params :time, :width
    after_save :file_state_update
  end

  def ad_effective_width
    if width && width > 0
      width
    else
      DEFAULT_SLIDE_WIDTH
    end
  end

  def ad_options
    options = {
      speed: DEFAULT_SLIDE_SPEED, navigation: true, pagination: true, "pagination-clickable" => true
    }
    options["autoplay-delay"] = time && time > 0 ? time * 1000 : DEFAULT_SLIDE_PAUSE
    options["autoplay-disable-on-interaction"] = false

    # a11y
    options["a11y-first-slide-message"] = I18n.t("ss.swiper_slide.first_slide_message")
    options["a11y-last-slide-message"] = I18n.t("ss.swiper_slide.last_slide_message")
    options["a11y-prev-slide-message"] = I18n.t("ss.swiper_slide.prev_slide_message")
    options["a11y-next-slide-message"] = I18n.t("ss.swiper_slide.next_slide_message")
    options["a11y-pagination-bullet-message"] = I18n.t("ss.swiper_slide.pagination_bullet_message")

    options
  end

  private

  def file_state_update
    files.each { |file| file.update(state: "public") }
  end
end
