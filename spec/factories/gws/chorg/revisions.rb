FactoryBot.define do
  factory :gws_revision, class: Gws::Chorg::Revision do
    name { "組織変更_#{unique_id}" }
  end

  factory :gws_revision_root_group, parent: :gws_group do
    name { "組織変更" }
  end

  factory :gws_revision_new_group, parent: :gws_group do
    name { "組織変更/グループ#{unique_id}" }
    ldap_dn { "ou=group,dc=example,dc=jp" }
  end
end
