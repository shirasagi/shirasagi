FactoryGirl.define do
  factory :webmail_user, class: SS::User do
    conf = SS.config.webmail.test_user || {}

    name 'user_name'
    email conf['email'] || 'webmail@example.jp'
    in_password 'pass'

    setting = Webmail::ImapSetting.new
    setting[:imap_host] = conf['host'] || 'localhost'
    setting[:imap_account] = conf['account'] || 'email'
    setting[:in_imap_password] = conf['password'] || 'pass'
    setting.set_imap_password

    imap_settings Webmail::Extensions::ImapSettings.new([setting])
  end
end
