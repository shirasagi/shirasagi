FactoryGirl.define do
  factory :ads_access_log, class: Ads::AccessLog do
    cur_site { cms_site }
    link_url { "http://example.jp/#{unique_id}" }
    date { Time.zone.now }
    count { rand(10) }
  end
end
