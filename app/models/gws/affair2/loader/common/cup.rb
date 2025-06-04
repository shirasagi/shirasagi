class Gws::Affair2::Loader::Common::Cup
  include ActiveModel::Model
  attr_reader :threshold, :value

  def initialize(threshold)
    @threshold = threshold
    @value = 0
    @threshold = 0 if threshold < 0
  end

  def pour(v)
    if @threshold > v
      @threshold = @threshold - v
      @value += v
      return 0
    else
      overflows = v - @threshold
      @value += @threshold
      @threshold = 0
      return overflows
    end
  end
end
