FactoryBot.define do
  factory :revision, class: Chorg::Revision do
    name { "組織変更_#{unique_id}" }
  end

  factory :revision_root_group, parent: :cms_group do
    name { "組織変更" }
  end

  factory :revision_new_group, parent: :cms_group do
    name { "組織変更/グループ#{unique_id}" }
    contact_groups do
      [
        {
          main_state: "main",
          name: "main",
          contact_group_name: name.split("/", 2).last,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_email: "#{unique_id}@example.jp",
          contact_postal_code: unique_id,
          contact_address: "address-#{unique_id}",
          contact_link_url: "/#{unique_id}/",
          contact_link_name: unique_id.to_s,
        }
      ]
    end
    ldap_dn { "ou=group,dc=example,dc=jp" }
  end

  factory :revision_page, class: Article::Page do
    transient do
      group { nil }
    end

    cur_site { site }
    name { "自動交付機・コンビニ交付サービスについて" }
    filename { group.contact_email.try(:gsub, /[@.]+/, "_") }
    layout_id { 10 }
    group_ids { [ group.id ] }
    contact_group_id { group.id }
    contact_group_contact_id { group.contact_groups.where(main_state: "main").first.try(:id) }
    contact_group_relation { group.contact_groups.where(main_state: "main").first ? "related" : nil }
    contact_charge { group.contact_groups.where(main_state: "main").first.try(:contact_group_name) }
    contact_tel { group.contact_groups.where(main_state: "main").first.try(:contact_tel) }
    contact_fax { group.contact_groups.where(main_state: "main").first.try(:contact_fax) }
    contact_email { group.contact_groups.where(main_state: "main").first.try(:contact_email) }
    contact_postal_code { group.contact_groups.where(main_state: "main").first.try(:contact_postal_code) }
    contact_address { group.contact_groups.where(main_state: "main").first.try(:contact_address) }
    contact_link_url { group.contact_groups.where(main_state: "main").first.try(:contact_link_url) }
    contact_link_name { group.contact_groups.where(main_state: "main").first.try(:contact_link_name) }
    state { "public" }
    order { 0 }
    category_ids { [ 83, 88, 128, 129, 135, 136 ] }
    permission_level { 1 }
  end
end
