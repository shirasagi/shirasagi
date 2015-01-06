FactoryGirl.define do
  factory :kana_dictionary, class: Kana::Dictionary do
    site_id { cms_site.id }
    name "#{unique_id}"
    body "シラサギ市, しらさぎし\nSHIRASAGI, しらさぎ\nShirasagi, しらさぎ\nshirasagi, しらさぎ"
  end
end
