FactoryBot.define do
  factory :contact_group, class: Cms::Group do
    name { "contact_group" }
    contact_groups do
      [
        {
          name: "name-#{unique_id}",
          contact_group_name: "contact_group_name-#{unique_id}",
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_email: unique_email,
          contact_postal_code: unique_id,
          contact_address: "address-#{unique_id}",
          contact_link_url: "/#{unique_id}",
          contact_link_name: "link_name-#{unique_id}",
          main_state: "main"
        }
      ]
    end
  end
end
