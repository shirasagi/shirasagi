def create_gws_users
  return if Gws::User.where(name: 'gws-admin').exists?

  g00 = SS::Group.create name: "シラサギ市", order: 10
  g10 = SS::Group.create name: "シラサギ市/企画政策部", order: 20
  g11 = SS::Group.create name: "シラサギ市/企画政策部/政策課", order: 30

  role = Gws::Role.create name: I18n.t('gws.roles.admin'), site_id: g00.id,
    permissions: Gws::Role.permission_names, permission_level: 3

  sys = Gws::User.create name: "gws-sys", uid: "sys", email: "sys@example.jp", in_password: "pass",
    group_ids: [g11.id], gws_role_ids: [role.id]
  adm = Gws::User.create name: "gw-admin", uid: "admin", email: "admin@example.jp", in_password: "pass",
    group_ids: [g11.id], gws_role_ids: [role.id]
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
