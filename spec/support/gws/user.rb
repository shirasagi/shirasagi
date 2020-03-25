module Gws
  module UserSupport
    cattr_accessor :data

    module Hooks
      def self.extended(obj)
        dbscope = obj.metadata[:dbscope]
        dbscope ||= RSpec.configuration.default_dbscope

        obj.after(dbscope) do
          Gws::UserSupport.data = nil
        end
      end
    end
  end
end

RSpec.configuration.extend(Gws::UserSupport::Hooks)

def gws_site
  create_gws_users[:site]
end

def gws_user
  create_gws_users[:user]
end

def gws_sys_user
  create_gws_users[:sys_user]
end

def login_gws_user
  login_user(gws_user)
end

def create_gws_users
  return Gws::UserSupport.data if Gws::UserSupport.data.present?

  g00 = Gws::Group.create name: "シラサギ市", order: 10
  g10 = Gws::Group.create name: "シラサギ市/企画政策部", order: 20
  g11 = Gws::Group.create name: "シラサギ市/企画政策部/政策課", order: 30

  if RSpec.current_example.try(:metadata).to_h[:es]
    g00.menu_elasticsearch_state = 'show'
    g00.elasticsearch_hosts = 'http://localhost:9200'
    g00.save!
  end

  role = Gws::Role.create name: I18n.t('gws.roles.admin'), site_id: g00.id,
    permissions: Gws::Role.permission_names, permission_level: 3

  user = Gws::User.create name: "gw-admin", uid: "admin", email: "admin@example.jp", in_password: "pass",
    group_ids: [g11.id], gws_role_ids: [role.id],
    organization_id: g00.id, organization_uid: "org-admin",
    deletion_lock_state: "locked"
  if user.invalid?
    user = Gws::User.find_by(email: "admin@example.jp")
    user.add_to_set(group_ids: g11.id, gws_role_ids: role.id)
    user.set(organization_id: g00.id, organization_uid: "org-admin", deletion_lock_state: "locked")
    user.in_password = "pass"
  end

  sys = Gws::User.create name: "gws-sys", uid: "sys", email: "sys@example.jp", in_password: "pass",
    group_ids: [g11.id], gws_role_ids: [role.id]
  if sys.invalid?
    sys = Gws::User.find_by(email: "sys@example.jp")
    sys.add_to_set(group_ids: g11.id, gws_role_ids: role.id)
    sys.in_password = "pass"
  end

  sys_role_gws = Sys::Role.where(name: build(:sys_role_gws, cur_user: sys).name).first
  sys_role_gws ||= create(:sys_role_gws, cur_user: sys)
  user.sys_user.add_to_set(sys_role_ids: sys_role_gws.id)
  sys.sys_user.add_to_set(sys_role_ids: sys_role_gws.id)

  user.cur_site = g00

  return Gws::UserSupport.data = {
    site: g00,
    user: user,
    sys_user: sys
  }
end
