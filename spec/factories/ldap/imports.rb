FactoryGirl.define do
  factory :ldap_import, class: Ldap::Import do
    cur_site { ss_site }
    group_count 3
    user_count 2
    ldap [ { type: "group", dn: "ou=001企画部,dc=city,dc=shirasagi,dc=jp", name: "001企画部" },
           { type: "group", dn: "ou=001001部長室,ou=001企画部,dc=city,dc=shirasagi,dc=jp",
             name: "001001部長室", parent_dn: "ou=001企画部,dc=city,dc=shirasagi,dc=jp" },
           { type: "group", dn: "ou=001002秘書広報課,ou=001企画部,dc=city,dc=shirasagi,dc=jp",
             name: "001002秘書広報課", parent_dn: "ou=001企画部,dc=city,dc=shirasagi,dc=jp" },
           { type: "user", dn: "uid=admin,ou=001002秘書広報課,ou=001企画部,dc=city,dc=shirasagi,dc=jp",
             name: "サイト管理者", uid: "admin", email: "admin@example.jp",
             parent_dn: "ou=001002秘書広報課,ou=001企画部,dc=city,dc=shirasagi,dc=jp" },
           { type: "user", dn: "uid=user1,ou=001002秘書広報課,ou=001企画部,dc=city,dc=shirasagi,dc=jp",
             name: "徳島　太郎", uid: "user1", email: "user1@example.jp",
             parent_dn: "ou=001002秘書広報課,ou=001企画部,dc=city,dc=shirasagi,dc=jp" } ]
  end
end
