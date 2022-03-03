# user class for webmail account export
class Webmail::User
  include SS::Model::User
  include SS::Reference::UserTitles
  include SS::Reference::UserOccupations
  include Webmail::Addon::UserExtension
  include Webmail::Addon::Role
  include Webmail::Permission
  include Sys::Reference::Role

  set_permission_name "webmail_users", :edit

  # override SS::Model::User#groups
  def groups
    Webmail::Group.where("$and" => [{ :_id.in => group_ids }])
  end
end
