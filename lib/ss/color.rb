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
  end
end
