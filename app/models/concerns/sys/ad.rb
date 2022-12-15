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
    options = { autoplay: "started", speed: DEFAULT_SLIDE_SPEED, navigation: "show", pagination_style: "disc" }
    options[:pause] = time && time > 0 ? time * 1000 : DEFAULT_SLIDE_PAUSE
    options
  end

  private

  def file_state_update
    files.each { |file| file.update_attributes(state: "public") }
  end
end
