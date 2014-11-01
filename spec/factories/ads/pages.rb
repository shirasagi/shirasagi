FactoryGirl.define do
  factory :ads_banner, class: Ads::Banner, traits: [:cms_page] do
    filename { "dir/#{unique_id}" }
    route "ads/banner"
    link_url "http://example.jp/"
    file_id 1
  end
end
