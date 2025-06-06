module Gws::Affair2::TimeCardFilter
  extend ActiveSupport::Concern

  included do
    helper_method :time_card_forms_path
    helper Gws::Affair2::TimeCardHelper
  end

  def time_card_forms_path(field_name, mode, *args)
    path = "gws_affair2_time_card_forms_#{mode}_#{field_name}_path"
    send(path, *args)
  end
end
