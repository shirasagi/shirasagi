# user class for webmail account export
class Webmail::User
  include SS::Model::User
  include Sys::Addon::Role
  include Sys::Reference::Role
  include Sys::Permission
  include Webmail::UserExtension
  include Webmail::AccountExport

  set_permission_name "sys_users", :edit
end
