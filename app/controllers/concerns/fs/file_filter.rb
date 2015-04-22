require 'rmagick'

module Fs::FileFilter
  extend ActiveSupport::Concern

  private
    def send_thumb(data, opts = {})
      width  = opts.delete(:width).to_i
      height = opts.delete(:height).to_i

      width  = (width  > 0) ? width  : 120
      height = (height > 0) ? height : 90

      image = Magick::Image.from_blob(data).shift
      image = image.resize_to_fit width, height if image.columns > width || image.rows > height

      send_data image.to_blob, opts
    end
end
