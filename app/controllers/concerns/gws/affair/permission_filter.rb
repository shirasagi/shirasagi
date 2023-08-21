module Gws::Affair::PermissionFilter
  extend ActiveSupport::Concern

  included do
    helper_method :module_name
  end

  private

  def module_name
    "gws_affair_attendance_time_cards"
  end
end
