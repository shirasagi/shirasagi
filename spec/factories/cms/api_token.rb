FactoryBot.define do
  factory :cms_api_token, class: Cms::ApiToken do
    cur_site { cms_site }
    cur_user { cms_user }
    audience { cms_user }
    name { unique_id }
  end
end
