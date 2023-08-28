module Gws::Schedule::Colorize
  extend ActiveSupport::Concern
  extend SS::Translation

  def brightness
    SS::Color.brightness(self.color)
  end

  def text_color
    SS::Color.text_color(self.color)
  end
end
