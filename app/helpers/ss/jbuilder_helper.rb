module SS::JbuilderHelper
  def format_json_datetime(json, item)
    format = SS.config.env.json_datetime_format
    return if format.blank?
    item.class.fields.to_h.each do |k, v|
      next unless %w(Date DateTime Time TimeWithZone).index(v.type.to_s)
      json.set!(k, @item.send(k).strftime(format)) rescue next
    end
  end
end
