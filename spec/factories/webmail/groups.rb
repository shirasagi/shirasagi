FactoryBot.define do
  factory :webmail_group, class: Webmail::Group do
    conf = SS.config.webmail.test_user || {}

    name { "group-#{unique_id}" }
    contact_email { "#{name}@example.jp" }

    setting = Webmail::ImapSetting.default
    setting[:imap_host] = conf['host'] || 'localhost'
    setting[:imap_account] = conf['account'] || 'email'
    setting[:in_imap_password] = conf['password'] || 'pass'
    setting.set_imap_password

    imap_settings Webmail::Extensions::ImapSettings.new([setting])
  end

  factory :webmail_group_with_no_imap, class: Webmail::Group do
    name { "group-#{unique_id}" }
  end
end
