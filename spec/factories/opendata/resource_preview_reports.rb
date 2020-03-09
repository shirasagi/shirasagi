FactoryBot.define do
  factory :opendata_resource_preview_report, class: Opendata::ResourcePreviewReport do
    cur_site { cms_site }
    year_month { Time.zone.now.year * 100 + Time.zone.now.month }
    dataset_id { rand(1..100) }
    dataset_name { "dataset-#{unique_id}" }
    dataset_url { "http://example.jp/#{dataset_name}.html" }
    dataset_areas { Array.new(2) { "area-#{unique_id}" } }
    dataset_categories { Array.new(2) { "cate-#{unique_id}" } }
    dataset_estat_categories { Array.new(2) { "estat-#{unique_id}" } }
    resource_id { rand(1..100) }
    resource_name { "res-#{unique_id}" }
    resource_filename { "#{resource_name}.#{%w(csv pdf).sample}" }
  end
end
