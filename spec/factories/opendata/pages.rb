FactoryGirl.define do
  factory :opendata_dataset, class: Opendata::Dataset, traits: [:cms_page] do
    filename { "dir/#{unique_id}" }
    route "opendata/dataset"
    text "aaaa\naaaa"
    related_url "http://example.jp"
    tags ["aaa", "bbb"]
    category_ids [1]
    area_ids [1]
    dataset_group_ids [1]
  end
end
