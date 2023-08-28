class Gws::Affair::Subtractor
  attr_reader :threshold

  def initialize(threshold)
    @threshold = (threshold.to_i > 0) ? threshold.to_i : 0
  end

  def subtract(*minutes)
    under_minutes = []
    over_minutes = []

    minutes.each do |minute|
      if @threshold > minute
        under_minutes << minute
        over_minutes << 0
      else
        under_minutes << @threshold
        over_minutes << minute - @threshold
      end

      @threshold = (@threshold - minute) > 0 ? @threshold - minute : 0
    end

    [under_minutes, over_minutes]
  end
end
