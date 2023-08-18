class SS::Color
  class << self
    def parse(color)
      return if color.blank?

      color = color[1..-1] if color.start_with?("#")
      case color.length
      when 3
        red = color[0] * 2
        green = color[1] * 2
        blue = color[2] * 2
      when 6
        red = color[0..1]
        green = color[2..3]
        blue = color[4..5]
      end
      return if !red || !green || !blue

      numeric_red = red.hex
      return if numeric_red == 0 && red != "00"

      numeric_green = green.hex
      return if numeric_green == 0 && green != "00"

      numeric_blue = blue.hex
      return if numeric_blue == 0 && blue != "00"

      SS::RandomColor::Rgb.new(numeric_red, numeric_green, numeric_blue)
    end

    def brightness(color)
      return if color.blank?

      rgb = SS::Color.parse(color)
      return unless rgb

      ((rgb.red * 299) + (rgb.green * 587) + (rgb.blue * 114)).to_f / 1000
    end

    def text_color(color)
      bgb = brightness(color)
      return nil if bgb.blank?

      (255 - bgb > bgb - 0) ? "#ffffff" : "#000000"
    end
  end
end
