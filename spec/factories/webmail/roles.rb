FactoryBot.define do
  factory :webmail_role, class: Webmail::Role do
    name { unique_id }
    permissions { Webmail::Role.permission_names.sample(rand(1..Webmail::Role.permission_names.length)) }
  end

  factory :webmail_role_admin, class: Webmail::Role do
    name { unique_id }
    permissions { Webmail::Role.permission_names }
  end

  factory :webmail_role_user, class: Webmail::Role do
    name { unique_id }
    permissions { %w(use_webmail_group_imap_setting) }
  end
end
