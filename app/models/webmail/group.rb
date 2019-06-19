class Webmail::Group
  include SS::Model::Group
  include Webmail::Permission
  include Contact::Addon::Group
  include Webmail::Addon::GroupExtension

  set_permission_name "webmail_groups", :edit

  # attr_accessor :sys_role_ids
  # permit_params :sys_role_ids

  def users
    Webmail::User.in(group_ids: id)
  end
end
