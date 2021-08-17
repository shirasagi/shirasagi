class Cms::CheckLinks::RefString < String
  attr_accessor :offset
  attr_accessor :inner_yield

  def meta
    { offset: offset, inner_yield: inner_yield }
  end

  def initialize(str, *args)
    super(str)
    options = args.extract_options!
    @offset = options[:offset].presence || []
    @inner_yield = options[:inner_yield].presence || false
  end
end
