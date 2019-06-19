FactoryBot.define do
  trait :gws_portal_portlet_base do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    limit 1
  end

  factory :gws_portal_user_portlet, class: Gws::Portal::UserPortlet, traits: [:gws_portal_portlet_base] do
    portlet_model ''
  end

  factory :gws_portal_group_portlet, class: Gws::Portal::GroupPortlet, traits: [:gws_portal_portlet_base] do
    portlet_model ''
  end
end
