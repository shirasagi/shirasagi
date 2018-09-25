# user class for webmail account export
class Webmail::User
  include SS::Model::User
  include SS::Reference::UserTitles
  include Webmail::Addon::Role
  include Webmail::Permission
  include Webmail::UserExtension
  include Webmail::AccountExport

  set_permission_name "webmail_users", :edit
end
