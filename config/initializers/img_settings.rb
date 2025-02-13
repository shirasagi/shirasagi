# Image settings configuration
module ImgSettings
  DEFAULT_THUMB_WIDTH = 360 unless defined?(DEFAULT_THUMB_WIDTH)
  DEFAULT_THUMB_HEIGHT = 360 unless defined?(DEFAULT_THUMB_HEIGHT)

  DEFAULT_THUMB_SIZE = [360, 360].freeze unless defined?(DEFAULT_THUMB_SIZE)
end
