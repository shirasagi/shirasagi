class Sys::PrefectureCode
  include SS::Model::PrefectureCode
  include Sys::Permission

  set_permission_name "sys_settings", :edit
end
