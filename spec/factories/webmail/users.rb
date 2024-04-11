FactoryBot.define do
  factory :webmail_user, class: Webmail::User do
    name { 'user_name' }
    email do
      conf = SS::WebmailSupport.test_conf
      conf['email'] || 'webmail@example.jp'
    end
    uid { email.split("@")[0] }
    in_password { 'pass' }
    type { SS::Model::User::TYPE_SNS }
    group_ids { [ ss_group.id ] }
    imap_settings do
      conf = SS::WebmailSupport.test_conf

      setting = Webmail::ImapSetting.default
      setting[:imap_host] = conf['host'] || 'localhost'
      setting[:imap_port] = conf['imap_port'] if conf.key?('imap_port')
      setting[:imap_ssl_use] = conf['imap_ssl_use'] if conf.key?('imap_ssl_use')
      setting[:imap_auth_type] = conf['imap_auth_type'] if conf.key?('imap_auth_typed')
      setting[:imap_account] = conf['account'] || 'email'
      setting[:in_imap_password] = conf['password'] || 'pass'
      setting.set_imap_password

      Webmail::Extensions::ImapSettings.new([setting])
    end
  end

  factory :webmail_user_without_imap, class: Webmail::User do
    name { "webmail-user-#{unique_id}" }
    email { "#{name}@example.jp" }
    in_password { 'pass' }
    type { SS::Model::User::TYPE_SNS }
    group_ids { [ ss_group.id ] }
  end
end
