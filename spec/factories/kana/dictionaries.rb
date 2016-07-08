FactoryGirl.define do
  factory :kana_dictionary, class: Kana::Dictionary do
    cur_site { cms_site }
    name { unique_id.to_s }
    body "シラサギ市, しらさぎし\nSHIRASAGI, しらさぎ\nShirasagi, しらさぎ\nshirasagi, しらさぎ"
  end

  factory :kana_dictionary_with_3_errors, class: Kana::Dictionary do
    cur_site { cms_site }
    name { unique_id.to_s }
    body "シラサギ市, \n, しらさぎ\nShirasagi, Shirasagi\nshirasagi, しらさぎ"
  end
end
