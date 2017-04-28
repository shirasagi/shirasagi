FactoryGirl.define do
  factory :webmail_user, class: SS::User do
    conf = SS.config.webmail.test_user || {}

    name "user_name"
    in_password "pass"
    email conf['email']
    imap_account conf['account']
    in_imap_password conf['password']
  end
end
