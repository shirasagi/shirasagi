class Gws::Affair2::Attendance::Groups < Gws::Affair2::Loader::DailyGroups::View
  include ActiveModel::Model
  include SS::Permission
  include Gws::Affair2::SubGroupPermission

  set_permission_name "gws_affair2_attendance_groups"
end
