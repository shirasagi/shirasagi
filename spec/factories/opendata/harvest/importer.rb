FactoryBot.define do
  factory :opendata_harvest_importer, class: Opendata::Harvest::Importer do
    cur_site { cms_site }
    name { unique_id }
    source_url { "https://#{unique_id}.example.jp/" }
    api_type { "shirasagi_api" }
  end
end
