FactoryGirl.define do
  factory :opendata_dataset, class: Opendata::Dataset, traits: [:cms_page] do
    transient do
      node nil
    end

    filename { node.blank? ? "dir/#{unique_id}.html" : "#{node.filename}/#{unique_id}.html" }
    route "opendata/dataset"
    text "aaaa\naaaa"
    tags ["aaa", "bbb"]
    category_ids [1]
    area_ids [1]
    dataset_group_ids [1]
  end

  factory :opendata_app, class: Opendata::App, traits: [:cms_page] do
    transient do
      node nil
    end

    filename { node.blank? ? "dir/#{unique_id}.html" : "#{node.filename}/#{unique_id}.html" }
    route "opendata/app"
    text "aaaa\naaaa"
    tags ["aaa", "bbb"]
    category_ids [1]
    area_ids [1]
    license { unique_id }
  end

  factory :opendata_idea, class: Opendata::Idea, traits: [:cms_page] do
    transient do
      node nil
    end

    filename { node.blank? ? "dir/#{unique_id}.html" : "#{node.filename}/#{unique_id}.html" }
    route "opendata/idea"
    text "cccc\ndddd"
    tags ["ccc", "ddd"]
    category_ids [1]
    area_ids [1]
  end

  factory :opendata_resource, class: Opendata::Resource do
    name { "#{unique_id}" }
    text "bbbb\nbbbb"
  end

  factory :opendata_url_resource, class: Opendata::Resource do
    name { "#{unique_id}" }
    text "eeee\nffff"
  end

end

