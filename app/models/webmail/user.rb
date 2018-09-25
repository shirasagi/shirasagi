# user class for webmail account export
class Webmail::User
  include SS::Model::User
  include SS::Reference::UserTitles
  include Webmail::Addon::UserExtension
  include Webmail::Addon::Role
  include Webmail::Permission

  set_permission_name "webmail_users", :edit
end
