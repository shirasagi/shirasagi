class Gws::Facility::UsageAggregator
  def initialize(criteria, type)
    @criteria = criteria
    @type = type
  end

  def aggregate
    results = @criteria.pluck(:allday, :start_at, :end_at, :facility_ids)
    results = normalize!(results)

    if @type == :month
      results = process_over_day_end(results)
      results = add_monthly_aggregation_key!(results)
    else
      results = process_over_month_end(results)
      results = add_yearly_aggregation_key!(results)
    end

    results = results.each_with_object({}) do |(key, usage_seconds), memo|
      if memo[key].blank?
        memo[key] = [ usage_seconds, 1 ]
      else
        memo[key][0] += usage_seconds
        memo[key][1] += 1
      end
    end

    results.map do |key, item|
      {
        "_id" => key,
        "count" => item[1],
        "total_usage_hours" => item[0] / (60 * 60.0)
      }
    end
  end

  private

  def normalize!(results)
    results.map! do |allday, start_at, end_at, facility_ids|
      start_at = start_at.in_time_zone
      end_at = end_at.in_time_zone
      end_at = end_at.beginning_of_day + 1.day if allday == "allday"

      [ start_at, end_at, facility_ids ]
    end
    results
  end

  def same_month?(lhs, rhs)
    lhs.year == rhs.year && lhs.month == rhs.month
  end

  def same_day?(lhs, rhs)
    same_month?(lhs, rhs) && lhs.day == rhs.day
  end

  def process_over_day_end(results)
    results.each_with_object([]) do |(start_at, end_at, facility_ids), memo|
      until same_day?(start_at, end_at)
        next_day = start_at.beginning_of_day + 1.day
        usage_seconds = next_day - start_at
        memo << [ start_at, facility_ids, usage_seconds ]
        start_at = next_day
      end

      usage_seconds = end_at - start_at
      memo << [ start_at, facility_ids, usage_seconds ] if usage_seconds > 0
    end
  end

  def add_monthly_aggregation_key!(results)
    results.map! do |start_at, facility_ids, usage_seconds|
      key = {
        "year" => start_at.year,
        "month" => start_at.month,
        "day" => start_at.day
      }
      facility_ids.map { |facility_id| [ key.merge("facility_id" => facility_id), usage_seconds ] }
    end
    results.flatten!(1)
    results
  end

  def process_over_month_end(results)
    results.each_with_object([]) do |(start_at, end_at, facility_ids), memo|
      until same_month?(start_at, end_at)
        next_day = start_at.beginning_of_month + 1.month
        usage_seconds = next_day - start_at
        memo << [ start_at, facility_ids, usage_seconds ]
        start_at = next_day
      end

      usage_seconds = end_at - start_at
      memo << [ start_at, facility_ids, usage_seconds ] if usage_seconds > 0
    end
  end

  def add_yearly_aggregation_key!(results)
    results.map! do |start_at, facility_ids, usage_seconds|
      key = {
        "year" => start_at.year,
        "month" => start_at.month
      }
      facility_ids.map { |facility_id| [ key.merge("facility_id" => facility_id), usage_seconds ] }
    end
    results.flatten!(1)
    results
  end
end
