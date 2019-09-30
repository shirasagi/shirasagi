class Gws::Affair::Enumerator::Base < Enumerator
  def bom
    return '' if @encoding == 'Shift_JIS'
    "\uFEFF"
  end

  def encode(str)
    return '' if str.blank?

    str = str.encode('CP932', invalid: :replace, undef: :replace) if @encoding == 'Shift_JIS'
    str
  end

  def format_minute(minute)
    (minute.to_i > 0) ? "#{minute / 60}:#{format("%02d", (minute % 60))}" : ""
  end

  def set_title_and_headers(yielder)
    if @title.present?
      yielder << bom + encode([@title].to_csv)
      yielder << encode(headers.to_csv)
    else
      yielder << bom + encode(headers.to_csv)
    end
  end
end
