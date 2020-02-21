class SS::ColorContrast
  class << self
    def from_css_color(css_color1, css_color2)
      l1 = relative_luminance(*split_rgb(css_color1))
      l2 = relative_luminance(*split_rgb(css_color2))

      if l1 > l2
        ratio(l1, l2)
      else
        ratio(l2, l1)
      end
    end

    def relative_luminance(red_8bit, green_8bit, blue_8bit)
      red = normalize_component(red_8bit / 255.0)
      green = normalize_component(green_8bit / 255.0)
      blue = normalize_component(blue_8bit / 255.0)

      0.2126 * red + 0.7152 * green + 0.0722 * blue
    end

    def ratio(lighter_luminance, darker_luminance)
      (lighter_luminance + 0.05) / (darker_luminance + 0.05)
    end

    private

    def normalize_component(value)
      if value <= 0.03928
        value / 12.92
      else
        ((value + 0.055) / 1.055) ** 2.4
      end
    end

    def split_rgb(css_color)
      css_color = css_color[1..-1] if css_color.starts_with?("#")

      raise "invalid css color format" if css_color.length != 3 && css_color.length != 6

      if css_color.length == 3
        r = css_color[0] * 2
        g = css_color[1] * 2
        b = css_color[2] * 2
      else
        r = css_color[0..1]
        g = css_color[2..3]
        b = css_color[4..5]
      end

      [ r.to_i(16), g.to_i(16), b.to_i(16) ]
    end
  end
end
