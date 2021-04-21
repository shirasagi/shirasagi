FactoryBot.define do
  factory :ldap_import, class: Ldap::Import do
    cur_site { ss_site }
    group_count 3
    user_count 2
    ldap [ { type: "group", dn: "ou=001企画政策部, dc=example, dc=jp", name: "001企画政策部" },
           { type: "group", dn: "ou=001001政策課, ou=001企画政策部, dc=example, dc=jp",
             name: "001001政策課", parent_dn: "ou=001企画政策部, dc=example, dc=jp" },
           { type: "group", dn: "ou=001002広報課, ou=001企画政策部, dc=example, dc=jp",
             name: "001002広報課", parent_dn: "ou=001企画政策部, dc=example, dc=jp" },
           { type: "user", dn: "uid=admin, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp",
             name: "サイト管理者", uid: "admin", email: "admin@example.jp",
             parent_dn: "ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" },
           { type: "user", dn: "uid=user1, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp",
             name: "鈴木 茂", uid: "user1", email: "user1@example.jp",
             parent_dn: "ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" } ]
  end
end
