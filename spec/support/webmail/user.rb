module Webmail
  module UserSupport
    cattr_accessor :data

    def self.extended(obj)
      dbscope = obj.metadata[:dbscope]
      dbscope ||= RSpec.configuration.default_dbscope

      obj.after(dbscope) do
        Webmail::UserSupport.data = nil
      end
    end
  end
end

RSpec.configuration.extend(Webmail::UserSupport)

def webmail_admin
  create_webmail_users[:admin]
end

def webmail_user
  create_webmail_users[:user]
end

def webmail_admin_role
  create_webmail_users[:admin_role]
end

def webmail_user_role
  create_webmail_users[:user_role]
end

def login_webmail_admin
  login_user(webmail_admin)
end

def login_webmail_user
  login_user(webmail_user)
end

def webmail_imap
  raise "not supported in imap: false" if SS::WebmailSupport.test_by.blank?
  create_webmail_users[:imap]
end

def login_webmail_imap
  raise "not supported in imap: false" if SS::WebmailSupport.test_by.blank?
  login_user(webmail_imap)
end

def create_webmail_users
  return Webmail::UserSupport.data if Webmail::UserSupport.data.present?

  g00 = SS::Group.create! name: "シラサギ市", order: 10
  g10 = SS::Group.create! name: "シラサギ市/企画政策部", order: 20
  g11 = SS::Group.create! name: "シラサギ市/企画政策部/政策課", order: 30

  admin_role = create(:webmail_role_admin, name: I18n.t('webmail.roles.admin'))
  user_role = create(:webmail_role_admin, name: I18n.t('webmail.roles.user'))

  admin = Webmail::User.create! name: "webmail-admin", uid: "admin", email: "admin@example.jp", in_password: "pass",
    group_ids: [g11.id], webmail_role_ids: [admin_role.id],
    organization_id: g00.id, organization_uid: "org-admin",
    deletion_lock_state: "locked"

  user = Webmail::User.create! name: "webmail-user", uid: "user", email: "user@example.jp", in_password: "pass",
    group_ids: [g11.id], webmail_role_ids: [user_role.id],
    organization_id: g00.id, organization_uid: "org-user"

  admin.in_password = admin.decrypted_password = 'pass'
  user.in_password = user.decrypted_password = 'pass'

  imap = nil
  if SS::WebmailSupport.test_by.present?
    imap = Webmail::User.create! name: "webmail-imap", uid: "imap",
      email: "imap@example.jp", in_password: SS.config.webmail.test_pass || "pass",
      group_ids: [g11.id], webmail_role_ids: [user_role.id],
      organization_id: g00.id, organization_uid: "org-imap"

    imap.imap_settings = webmail_imap_setting
    imap.save!

    imap.in_password = imap.decrypted_password = SS.config.webmail.test_pass || 'pass'
  end

  return Webmail::UserSupport.data = {
    admin: admin,
    user: user,
    admin_role: admin_role,
    user_role: user_role,
    imap: imap
  }
end

def webmail_imap_setting
  conf = SS::WebmailSupport.test_conf
  setting = Webmail::ImapSetting.default
  setting[:imap_host] = conf['host'] || 'localhost'
  setting[:imap_port] = conf['imap_port'] if conf.key?('imap_port')
  setting[:imap_ssl_use] = conf['imap_ssl_use'] if conf.key?('imap_ssl_use')
  setting[:imap_auth_type] = conf['imap_auth_type'] if conf.key?('imap_auth_type')
  setting[:imap_account] = conf['account'] || 'email'
  setting[:in_imap_password] = conf['password'] || 'pass'
  setting.set_imap_password
  Webmail::Extensions::ImapSettings.new([setting])
end
