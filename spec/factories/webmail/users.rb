FactoryGirl.define do
  factory :webmail_user, class: SS::User do
    name "user_name"
    in_password "pass"
    email SS.config.webmail.test_user['email']
    imap_account SS.config.webmail.test_user['account']
    in_imap_password SS.config.webmail.test_user['password']
  end
end
