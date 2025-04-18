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

    after_find do
      if __selected_fields.nil? || __selected_fields.key?("ad_links")
        @_ad_links_before_change = ad_links.map(&:dup)
      end
    end

    before_validation :normalize_ad_links

    validates :ad_links, length: { maximum: MAX_AD_LINK_COUNT }

    before_save :ad_delete_unlinked_files
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

  def ad_links_was
    return [] if new_record?
    @_ad_links_before_change || []
  end

  private

  def normalize_ad_links
    return if ad_links.blank?

    self.ad_links = ad_links.reject { blank_ad_link?(_1) }
  end

  def blank_ad_link?(ad_link)
    ad_link.name.blank? && ad_link.url.blank? && ad_link.file.blank?
  end

  def file_previewable?(file, site:, user:, member:)
    ad_link = ad_links.where(file_id: file.id).first
    return false unless ad_link

    ad_link.state == "show"
  end

  def ad_delete_unlinked_files
    return if new_record?

    file_ids_is = []
    self.ad_links.each do |ad_link|
      file_ids_is << ad_link.file_id
    end
    file_ids_is.compact!
    file_ids_is.uniq!

    file_ids_was = []
    self.ad_links_was.each do |ad_link|
      file_ids_was << ad_link.file_id
    end
    file_ids_was.compact!
    file_ids_was.uniq!

    unlinked_file_ids = file_ids_was - file_ids_is
    Cms::Reference::Files::Utils.delete_files(self, unlinked_file_ids)
  end
end
