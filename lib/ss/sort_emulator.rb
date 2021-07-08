class SS::SortEmulator
  attr_reader :criteria

  def initialize(criteria)
    @criteria = criteria
  end

  def order_by_array(sort_hash)
    begin
      @criteria.order_by(sort_hash).to_a
    rescue Mongo::Error::OperationFailure => e
      Rails.logger.error(e.to_s)
      Rails.logger.error("fall back to ruby sort : #{@criteria.marshal_dump}")
      @criteria.reorder(id: 1).to_a.sort { |lhs, rhs| page_sort_proc(sort_hash, lhs, rhs) }
    end
  end

  private

  def normalize_sort_direction(direction)
    case direction
    when 1, "1", "asc"
      1
    when -1, "-1", "desc"
      -1
    else
      1
    end
  end

  def compare_value_asc(lhs_val, rhs_val)
    if lhs_val.nil?
      if rhs_val.nil?
        0
      else
        # put nil first
        -1
      end
    elsif rhs_val.nil?
      # put nil first
      1
    else
      lhs_val <=> rhs_val
    end
  end

  def page_sort_proc(sort_hash, lhs, rhs)
    cmp = 0

    sort_hash.each_with_index do |sort, index|
      _field, direction = *sort
      lhs_val = lhs.send(_field)
      rhs_val = rhs.send(_field)

      if normalize_sort_direction(direction) > 0
        cmp = compare_value_asc(lhs_val, rhs_val)
      else
        cmp = compare_value_asc(rhs_val, lhs_val)
      end

      break if cmp != 0
    end

    if cmp == 0
      # fallback: compare ids
      cmp = compare_value_asc(lhs[0], rhs[0])
    end

    cmp
  end
end
