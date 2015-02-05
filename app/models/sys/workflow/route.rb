class Sys::Workflow::Route
  include Workflow::Route::Model
  include Sys::Permission

  set_permission_name "sys_users", :edit
end
