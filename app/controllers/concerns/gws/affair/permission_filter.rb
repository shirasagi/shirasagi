module Gws::Affair::PermissionFilter
  extend ActiveSupport::Concern

  included do
    helper_method :attendance_permission_name
  end

  private

  def attendance_permission_name
    "gws_affair_attendance_time_cards"
  end
end
