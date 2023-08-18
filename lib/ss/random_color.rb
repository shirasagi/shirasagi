class SS::RandomColor
  include Enumerable

  SALT = "8b11dbd151a96686bea8a094e31e626cb7bc16305288ddab7e921538a9578277".freeze
  SEGMENTS = [ 0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11 ].freeze

  class Hsl
    def initialize(hue, saturation, lightness)
      @hue = hue
      @saturation = saturation
      @lightness = lightness
    end

    attr_accessor :hue, :saturation, :lightness

    def to_s
      "hsl(#{hue},#{saturation}%,#{lightness}%)"
    end

    def to_hsl
      self
    end

    def lightness_min_max
      if lightness < 50
        max = 2.55 * (lightness + lightness * (saturation / 100.0))
        min = 2.55 * (lightness - lightness * (saturation / 100.0))
      else
        max = 2.55 * (lightness + (100 - lightness) * (saturation / 100.0))
        min = 2.55 * (lightness - (100 - lightness) * (saturation / 100.0))
      end

      [ min, max ]
    end

    def to_rgb
      min, max = lightness_min_max

      if hue <= 60
        r = max
        g = (hue / 60.0) * (max - min) + min
        b = min
      elsif hue <= 120
        r = ((120 - hue) / 60.0) * (max - min) + min
        g = max
        b = min
      elsif hue <= 180
        r = min
        g = max
        b = ((hue - 120) / 60.0) * (max - min) + min
      elsif hue <= 240
        r = min
        g = ((240 - hue) / 60.0) * (max - min) + min
        b = max
      elsif hue <= 300
        r = ((hue - 240) / 60.0) * (max - min) + min
        g = min
        b = max
      else
        r = max
        g = min
        b = ((360 - hue) / 60.0) * (max - min) + min
      end

      Rgb.new(r.to_i, g.to_i, b.to_i)
    end
  end

  class Rgb
    def initialize(red, green, blue)
      @red = red
      @green = green
      @blue = blue
    end

    attr_accessor :red, :green, :blue

    def to_s
      "##{red.to_s(16).rjust(2, "0")}#{green.to_s(16).rjust(2, "0")}#{blue.to_s(16).rjust(2, "0")}"
    end

    def to_rgb
      self
    end

    def to_hsl
      raise NotImplementedError
    end
  end

  def initialize(seed = ::Random.new_seed)
    if seed.numeric?
      seed = seed.to_i
    else
      seed = ::Digest::MD5.hexdigest(seed.to_s + SALT).to_i(16)
    end

    @rand = Random.new(seed)
    @count = 0
  end

  def next
    start = 360 / SEGMENTS.length * SEGMENTS[@count % SEGMENTS.length]
    close = start + 360 / SEGMENTS.length

    h = @rand.rand(start..close)
    s = @rand.rand(42..98)
    l = @rand.rand(40..90)

    Hsl.new(h, s, l)
  ensure
    @count += 1
  end

  def each
    return enum_for(:each) unless block_given?

    loop do
      yield self.next
    end
  end

  class << self
    def default_generator
      @default_generator ||= SS::RandomColor.new
    end

    def random_hsl
      default_generator.next
    end

    def random_rgb
      random_hsl.to_rgb
    end
  end
end
