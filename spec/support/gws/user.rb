module Gws
  module UserSupport
    cattr_accessor :data

    def self.extended(obj)
      dbscope = obj.metadata[:dbscope]
      dbscope ||= RSpec.configuration.default_dbscope

      obj.after(dbscope) do
        Gws::UserSupport.data = nil
      end
    end
  end
end

RSpec.configuration.extend(Gws::UserSupport)

def gws_site
  create_gws_users[:site]
end

def gws_user
  create_gws_users[:user]
end

def login_gws_user
  login_user(gws_user)
end

def create_gws_users
  return Gws::UserSupport.data if Gws::UserSupport.data.present?

  g00 = Gws::Group.create name: "シラサギ市", order: 10
  g10 = Gws::Group.create name: "シラサギ市/企画政策部", order: 20
  g11 = Gws::Group.create name: "シラサギ市/企画政策部/政策課", order: 30

  role = Gws::Role.create name: I18n.t('gws.roles.admin'), site_id: g00.id,
    permissions: Gws::Role.permission_names, permission_level: 3

  user = Gws::User.create name: "gw-admin", uid: "admin", email: "admin@example.jp", in_password: "pass",
    group_ids: [g11.id], gws_role_ids: [role.id],
    organization_id: g00.id, organization_uid: "org-admin"

  sys = Gws::User.create name: "gws-sys", uid: "sys", email: "sys@example.jp", in_password: "pass",
    group_ids: [g11.id], gws_role_ids: [role.id]

  user.cur_site = g00

  return Gws::UserSupport.data = {
    site: g00,
    user: user
  }
end
