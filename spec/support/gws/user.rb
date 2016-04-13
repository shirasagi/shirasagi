def create_gws_users
  return if SS::Group.all.present?

  g00 = SS::Group.create name: "シラサギ市", order: 10
  g10 = SS::Group.create name: "シラサギ市/企画政策部", order: 20
  g11 = SS::Group.create name: "シラサギ市/企画政策部/政策課", order: 30
  #g12 = SS::Group.create name: "シラサギ市/企画政策部/広報課", order: 40
  #g20 = SS::Group.create name: "シラサギ市/危機管理部", order: 50
  #g21 = SS::Group.create name: "シラサギ市/危機管理部/管理課", order: 60
  #g22 = SS::Group.create name: "シラサギ市/危機管理部/防災課", order: 70

  role = Gws::Role.create name: I18n.t('gws.roles.admin'), site_id: g00.id,
    permissions: Gws::Role.permission_names, permission_level: 3

  sys = Gws::User.create name: "システム管理者", uid: "sys", email: "sys@example.jp", in_password: "pass",
    group_ids: [g11.id], gws_role_ids: [role.id]
  adm = Gws::User.create name: "サイト管理者", uid: "admin", email: "admin@example.jp", in_password: "pass",
    group_ids: [g11.id], gws_role_ids: [role.id]
  #u01 = Gws::User.create name: "一般ユーザー1", uid: "user1", email: "user1@example.jp", in_password: "pass",
  #  group_ids: [g11.id], gws_role_ids: [role.id]
  #u02 = Gws::User.create name: "一般ユーザー2", uid: "user2", email: "user2@example.jp", in_password: "pass",
  #  group_ids: [g21.id], gws_role_ids: [role.id]
  #u03 = Gws::User.create name: "一般ユーザー3", uid: "user3", email: "user3@example.jp", in_password: "pass",
  #  group_ids: [g12.id, g22.id], gws_role_ids: [role.id]
end

def gws_site
  create_gws_users
  Gws::Group.find_by name: 'シラサギ市'
end

def gws_user
  create_gws_users
  Gws::User.find_by uid: 'admin'
end

def login_gws_user
  login_user gws_user
end
