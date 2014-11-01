FactoryGirl.define do
  factory :ads_part_banner, class: Ads::Part::Banner, traits: [:cms_part] do
    route "ads/banner"
  end
end
