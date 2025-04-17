module Sys::Ad
  extend ActiveSupport::Concern
  extend SS::Translation
  include Fs::FilePreviewable

  DEFAULT_SLIDE_WIDTH = 360
  DEFAULT_SLIDE_SPEED = 500
  DEFAULT_SLIDE_PAUSE = 5000

  MAX_AD_LINK_COUNT = 100

  included do
    field :time, type: Integer
    field :width, type: Integer
    embeds_many :ad_links, class_name: "SS::LinkItem", cascade_callbacks: true, validate: true

    permit_params :time, :width, ad_links: %i[id name url file_id target state]

    before_validation :normalize_ad_links

    validates :ad_links, length: { maximum: MAX_AD_LINK_COUNT }

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

  def normalize_ad_links
    return if ad_links.blank?

    self.ad_links = ad_links.reject { blank_ad_link?(_1) }
  end

  def blank_ad_link?(ad_link)
    ad_link.name.blank? && ad_link.url.blank? && ad_link.file.blank?
  end

  def file_state_update
    SS::File.in(id: ad_links.pluck(:file_id)).set(state: "public")
  end

  def file_previewable?(file, site:, user:, member:)
    ad_link = ad_links.where(file_id: file.id).first
    return false unless ad_link

    ad_link.state == "show"
  end
end
