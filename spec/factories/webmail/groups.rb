FactoryBot.define do
  factory :webmail_group, class: Webmail::Group do
    name { "group-#{unique_id}" }
    contact_groups do
      [
        {
          name: "name-#{unique_id}",
          contact_email: "#{name}@example.jp",
          main_state: "main"
        }
      ]
    end
    imap_settings do
      conf = ::SS::WebmailSupport.test_conf

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

  factory :webmail_group_with_no_imap, class: Webmail::Group do
    name { "group-#{unique_id}" }
  end
end
