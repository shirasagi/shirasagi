def create_webmail_users
  return if Webmail::User.where(uid: 'admin').exists?

  g00 = SS::Group.create! name: "シラサギ市", order: 10
  g10 = SS::Group.create! name: "シラサギ市/企画政策部", order: 20
  g11 = SS::Group.create! name: "シラサギ市/企画政策部/政策課", order: 30

  admin_role = create(:webmail_role_admin, name: I18n.t('webmail.roles.admin'))
  user_role = create(:webmail_role_admin, name: I18n.t('webmail.roles.user'))

  adm = Webmail::User.create! name: "webmail-admin", uid: "admin", email: "admin@example.jp", in_password: "pass",
    group_ids: [g11.id], webmail_role_ids: [admin_role.id],
    organization_id: g00.id, organization_uid: "org-admin"
  user = Webmail::User.create! name: "webmail-user", uid: "user", email: "user@example.jp", in_password: "pass",
    group_ids: [g11.id], webmail_role_ids: [user_role.id],
    organization_id: g00.id, organization_uid: "org-user"
end

def webmail_user
  create_webmail_users
  user = Webmail::User.find_by(uid: 'user')
  user.in_password = 'pass'
  user
end

def webmail_admin
  create_webmail_users
  user = Webmail::User.find_by(uid: 'admin')
  user.in_password = 'pass'
  user
end

def webmail_admin_role
  create_webmail_users
  Webmail::Role.find_by(name: I18n.t('webmail.roles.admin'))
end

def webmail_user_role
  create_webmail_users
  Webmail::Role.find_by(name: I18n.t('webmail.roles.user'))
end

def login_webmail_user
  login_user webmail_user
end

def login_webmail_admin
  login_user webmail_admin
end
