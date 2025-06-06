class Gws::Affair2::Loader::Common::Cup
  include ActiveModel::Model

  attr_reader :threshold, :pool

  def initialize(threshold)
    @threshold = threshold
    @pool = 0
    @threshold = 0 if threshold < 0
  end

  def pour(value)
    if @threshold > value
      @threshold -= value
      @pool += value
      return 0
    else
      overflows = value - @threshold
      @pool += @threshold
      @threshold = 0
      return overflows
    end
  end
end
