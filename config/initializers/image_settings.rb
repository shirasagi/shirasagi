# Image settings configuration
module ImageSettings
  # lib/ss/image_converter.rb
  DEFAULT_THUMB_WIDTH = 360 unless defined?(DEFAULT_THUMB_WIDTH)
  DEFAULT_THUMB_HEIGHT = 360 unless defined?(DEFAULT_THUMB_HEIGHT)
  # app/models/member/photo_file.rb
  DEFAULT_THUMB_SIZE = [360, 360].freeze unless defined?(DEFAULT_THUMB_SIZE)
end
