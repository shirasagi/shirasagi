FactoryBot.define do
  factory :opendata_resource_download_history, class: Opendata::ResourceDownloadHistory do
    cur_site { cms_site }
    dataset_id { rand(10.20) }
    dataset_name { "dataset-#{unique_id}" }
    dataset_areas { Array.new(2) { "area-#{unique_id}" } }
    dataset_categories { Array.new(2) { "cate-#{unique_id}" } }
    dataset_estat_categories { Array.new(2) { "estat-#{unique_id}" } }
    resource_id { rand(20..30) }
    resource_name { "res-#{unique_id}" }
    resource_filename { "#{resource_name}.#{%w(csv pdf).sample}" }
    resource_source_url { resource_filename }
    full_url { "http://example.jp/#{dataset_name}.html" }
    downloaded { Time.zone.now }
    downloaded_by { %w(single dataset bulk).sample }
    remote_addr { "10.0.0.#{rand(0..255)}" }
    user_agent { "ua-#{unique_id}" }
  end
end
