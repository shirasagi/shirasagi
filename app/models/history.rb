module History
  module_function

  def term_to_date(name, date = nil)
    date ||= Time.zone.now
    case name
    when "all_delete"
      date
    when "all_save"
      nil
    else
      date - SS::Duration.parse(name)
    end
  end
end