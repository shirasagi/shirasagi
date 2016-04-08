module Gws::Schedule::Colorize
  extend ActiveSupport::Concern
  extend SS::Translation

  def brightness
    return nil if self.color.blank?

    color = self.color.sub(/^#/, '').sub(/^(.)(.)(.)$/, '\\1\\1\\2\\2\\3\\3')
    r, g, b = color.scan(/../).map { |c| c.hex }
    ((r * 299) + (g * 587) + (b * 114)).to_f / 1000
  end

  def text_color
    bgb = brightness
    return nil if bgb.blank?

    (255 - bgb > bgb - 0) ? "#ffffff" : "#000000"
  end
end
