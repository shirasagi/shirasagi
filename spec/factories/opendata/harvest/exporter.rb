FactoryBot.define do
  factory :opendata_harvest_exporter, class: Opendata::Harvest::Exporter do
    cur_site { cms_site }
    name { unique_id }
    url { "https://source.example.jp/" }
    api_type { "ckan_api" }
    api_key { SecureRandom.uuid }
  end
end
