class Sys::Notice
  include SS::Model::Notice
  include Sys::Permission

  set_permission_name "sys_notices", :edit
end
