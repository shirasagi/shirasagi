FactoryBot.define do
  factory :check_links_ignore_url, class: Cms::CheckLinks::IgnoreUrl do
    site { cms_site }
    name { unique_id }
  end
end
