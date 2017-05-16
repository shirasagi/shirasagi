FactoryGirl.define do
  factory :webmail_user, class: SS::User do
    conf = SS.config.webmail.test_user || {}

    name 'user_name'
    email conf['email'] || 'webmail@example.jp'
    in_password 'pass'

    imap_account conf['account'] || 'email'
    in_imap_password conf['password'] || 'pass'
  end
end
