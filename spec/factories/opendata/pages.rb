FactoryGirl.define do
  factory :opendata_dataset, class: Opendata::Dataset, traits: [:cms_page] do
    transient do
      node nil
    end

    filename { node.blank? ? "dir/#{unique_id}" : "#{node.filename}/#{unique_id}" }
    route "opendata/dataset"
    text "aaaa\naaaa"
    tags ["aaa", "bbb"]
    category_ids [1]
    area_ids [1]
    dataset_group_ids [1]
  end

  factory :opendata_app, class: Opendata::App, traits: [:cms_page] do
    filename { "dir/#{unique_id}" }
    route "opendata/app"
    text "aaaa\naaaa"
    tags ["aaa", "bbb"]
    category_ids [1]
    area_ids [1]
    license { unique_id }
  end

  factory :opendata_resource, class: Opendata::Resource do
    name { "#{unique_id}" }
    text "bbbb\nbbbb"
  end
end

