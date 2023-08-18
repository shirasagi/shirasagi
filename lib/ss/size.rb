class SS::Size
  def self.parse(size)
    size = size.to_s
    suffix = size[-1].downcase
    if %w(k m g t).include?(suffix)
      numeric_part = size[0..-2]
    else
      numeric_part = size
      suffix = nil
    end

    raise "malformed size: #{size}" if !numeric_part.numeric?
    return numeric_part.to_i if suffix.nil?

    numeric_part = numeric_part.to_i
    case suffix
    when "k" # Kilo
      numeric_part *= 1_024
    when "m" # Mega
      numeric_part *= 1_024 * 1_024
    when "g" # Giga
      numeric_part *= 1_024 * 1_024 * 1_024
    when "t" # Tera
      numeric_part *= 1_024 * 1_024 * 1_024 * 1_024
    end

    numeric_part
  end
end
