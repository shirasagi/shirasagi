FactoryGirl.define do
  factory :revision, class: Chorg::Revision do
    name { "組織変更_#{unique_id}" }
  end

  factory :revision_root_group, parent: :cms_group do
    name { "組織変更" }
  end

  factory :revision_new_group, parent: :cms_group do
    name { "組織変更/グループ#{unique_id}" }
    contact_email { "#{unique_id}@example.jp" }
    contact_tel "03-4389-8714"
    contact_fax "03-4389-8715"
    ldap_dn { "ou=group,dc=example,dc=jp" }
  end

  factory :revisoin_page, class: Article::Page do
    transient do
      group nil
    end

    cur_site { site }
    name "自動交付機・コンビニ交付サービスについて"
    filename { group.contact_email.gsub(/[@.]+/, "_") }
    layout_id 10
    group_ids { [ group.id ] }
    contact_group_id { group.id }
    contact_email { group.contact_email }
    contact_tel { group.contact_tel }
    contact_fax { group.contact_fax }
    state "public"
    order 0
    category_ids [ 83, 88, 128, 129, 135, 136 ]
    permission_level 1
  end
end
