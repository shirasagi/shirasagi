FactoryGirl.define do
  factory :cms_page_search, class: Cms::PageSearch do
    cur_site { cms_site }
    cur_user { cms_user }
    name { "name-#{unique_id}" }
  end
end
