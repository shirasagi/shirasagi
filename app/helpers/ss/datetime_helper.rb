module SS::DatetimeHelper
  def number_with_datetime_unit(object, method)
    [
      object.send(method),
      object.label(:"#{method}_unit")
    ].join
  end

  def number_field_with_datetime_unit(object, method, choices, options = {}, html_options = {}, &block)
    [
      number_field(object, method, options),
      select(object, :"#{method}_unit", choices, options, html_options, &block)
    ].join("\n").html_safe
  end
end
