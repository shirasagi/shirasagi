FactoryBot.define do
  factory :webmail_user, class: Webmail::User do
    conf = SS.config.webmail.test_user || {}

    name 'user_name'
    email conf['email'] || 'webmail@example.jp'
    in_password 'pass'
    group_ids { [ ss_group.id ] }

    setting = Webmail::ImapSetting.default
    setting[:imap_host] = conf['host'] || 'localhost'
    setting[:imap_account] = conf['account'] || 'email'
    setting[:in_imap_password] = conf['password'] || 'pass'
    setting.set_imap_password

    imap_settings Webmail::Extensions::ImapSettings.new([setting])
  end

  factory :webmail_user_without_imap, class: Webmail::User do
    name { "webmail-user-#{unique_id}" }
    email { "#{name}@example.jp" }
    in_password 'pass'
    group_ids { [ ss_group.id ] }
  end
end
