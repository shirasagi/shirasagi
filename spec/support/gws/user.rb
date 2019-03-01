def create_gws_users
  return if Gws::User.where(uid: 'admin').exists?

  g00 = SS::Group.create name: "シラサギ市", order: 10
  g10 = SS::Group.create name: "シラサギ市/企画政策部", order: 20
  g11 = SS::Group.create name: "シラサギ市/企画政策部/政策課", order: 30

  role = Gws::Role.create name: I18n.t('gws.roles.admin'), site_id: g00.id,
    permissions: Gws::Role.permission_names, permission_level: 3
  role_2 = Gws::Role.create name: I18n.t('gws.roles.user'), site_id: g00.id,
    permissions: load_gws_permissions('gws/roles/user_permissions.txt'), permission_level: 1

  sys = Gws::User.create name: "gws-sys", uid: "sys", email: "sys@example.jp", in_password: "pass",
    group_ids: [g11.id], gws_role_ids: [role.id]
  adm = Gws::User.create name: "gw-admin", uid: "admin", email: "admin@example.jp", in_password: "pass",
    group_ids: [g11.id], gws_role_ids: [role.id],
    organization_id: g00.id, organization_uid: "org-admin"
  user1 = Gws::User.create name: "gws-user1", uid: "user1", email: "user1@example.jp", in_password: "pass",
    group_ids: [g11.id], gws_role_ids: [role_2.id]
  user2 = Gws::User.create name: "gws-user2", uid: "user2", email: "user2@example.jp", in_password: "pass",
    group_ids: [g11.id], gws_role_ids: [role_2.id]
end

def load_gws_permissions(path)
  File.read("#{Rails.root}/db/seeds/#{path}").split(/\r?\n/).map(&:strip) & Gws::Role.permission_names
end

def gws_site
  create_gws_users
  Gws::Group.find_by name: 'シラサギ市'
end

def gws_user
  create_gws_users
  user = Gws::User.find_by uid: 'admin'
  user.cur_site = gws_site if user.present?
  user
end

def login_gws_user
  login_user gws_user
end
