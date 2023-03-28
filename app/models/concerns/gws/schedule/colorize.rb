module Gws::Schedule::Colorize
  extend ActiveSupport::Concern
  extend SS::Translation

  def brightness
    return nil if self.color.blank?

    rgb = SS::Color.parse(self.color)
    return nil unless rgb

    ((rgb.red * 299) + (rgb.green * 587) + (rgb.blue * 114)).to_f / 1000
  end

  def text_color
    bgb = brightness
    return nil if bgb.blank?

    (255 - bgb > bgb - 0) ? "#ffffff" : "#000000"
  end
end
