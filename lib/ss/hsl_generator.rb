class SS::HslGenerator
  include Enumerable

  SALT = "8b11dbd151a96686bea8a094e31e626cb7bc16305288ddab7e921538a9578277".freeze
  SEGMENTS = [ 0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11 ].freeze

  def initialize(seed = ::Random.new_seed)
    if seed.numeric?
      seed = seed.to_i
    else
      seed = ::Digest::MD5.hexdigest(seed.to_s + SALT).to_i(16)
    end

    @rand = Random.new(seed)
    @count = 0
  end

  def each
    loop do
      start = 360 / SEGMENTS.length * SEGMENTS[@count % SEGMENTS.length]
      close = start + 360 / SEGMENTS.length

      h = @rand.rand(start..close)
      s = @rand.rand(42..98)
      l = @rand.rand(40..90)

      yield "hsl(#{h},#{s}%,#{l}%)"
      @count += 1
    end
  end
end
