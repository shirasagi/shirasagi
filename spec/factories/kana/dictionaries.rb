FactoryGirl.define do
  factory :kana_dictionary, class: Kana::Dictionary do
    site_id { cms_site.id }
    name "#{unique_id}"
    body "シラサギ市, しらさぎし\nSHIRASAGI, しらさぎ\nShirasagi, しらさぎ\nshirasagi, しらさぎ"
  end

  factory :kana_dictionary_with_3_errors, class: Kana::Dictionary do
    site_id { cms_site.id }
    name "#{unique_id}"
    body "シラサギ市, \n, しらさぎ\nShirasagi, Shirasagi\nshirasagi, しらさぎ"
  end
end
