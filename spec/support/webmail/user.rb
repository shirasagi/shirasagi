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

  # rubocop:disable Rails/I18nLocaleAssignment
  I18n.locale = I18n.default_locale
  # rubocop:enable Rails/I18nLocaleAssignment
end

def login_webmail_user
  login_user(webmail_user)

  # rubocop:disable Rails/I18nLocaleAssignment
  I18n.locale = I18n.default_locale
  # rubocop:enable Rails/I18nLocaleAssignment
end

def webmail_imap
  raise "not supported in imap: false" if SS::WebmailSupport.test_by.blank?
  create_webmail_users[:imap]
end

def login_webmail_imap
  raise "not supported in imap: false" if SS::WebmailSupport.test_by.blank?
  login_user(webmail_imap)

  # rubocop:disable Rails/I18nLocaleAssignment
  I18n.locale = I18n.default_locale
  # rubocop:enable Rails/I18nLocaleAssignment
end

def create_webmail_users
  return Webmail::UserSupport.data if Webmail::UserSupport.data.present?

  create_gws_users

  g00 = SS::Group.find_by(name: "シラサギ市")
  g10 = SS::Group.find_by(name: "シラサギ市/企画政策部")
  g11 = SS::Group.find_by(name: "シラサギ市/企画政策部/政策課")

  admin_role = create(:webmail_role_admin, name: I18n.t('webmail.roles.admin'))
  user_role = create(:webmail_role_admin, name: I18n.t('webmail.roles.user'))

  gws_admin = Gws::User.find_by(email: "admin@example.jp")
  admin = gws_admin.webmail_user
  admin.update(webmail_role_ids: [admin_role.id])

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

    imap.gws_user.tap do |gws_user|
      gws_user.update!(gws_role_ids: gws_admin.gws_role_ids)
    end

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
