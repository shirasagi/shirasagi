FactoryGirl.define do
  factory :opendata_node_category, class: Opendata::Node::Category, traits: [:cms_node] do
    route "opendata/category"
    filename { "category-#{unique_id}" }
  end

  factory :opendata_node_area, class: Opendata::Node::Area, traits: [:cms_node] do
    route "opendata/area"
    filename { "area-#{unique_id}" }
  end

  factory :opendata_node_dataset, class: Opendata::Node::Dataset, traits: [:cms_node] do
    route "opendata/dataset"
    filename { "dataset-#{unique_id}" }
  end

  factory :opendata_node_dataset_category, class: Opendata::Node::DatasetCategory, traits: [:cms_node] do
    route "opendata/dataset_category"
    filename { "dataset-category-#{unique_id}" }
  end

  factory :opendata_node_app_category, class: Opendata::Node::AppCategory, traits: [:cms_node] do
    route "opendata/app_category"
    filename { "app-category-#{unique_id}" }
  end

  factory :opendata_node_idea_category, class: Opendata::Node::IdeaCategory, traits: [:cms_node] do
    route "opendata/idea_category"
    filename { "idea-category-#{unique_id}" }
  end

  factory :opendata_node_search_dataset_group, class: Opendata::Node::SearchDatasetGroup, traits: [:cms_node] do
    route "opendata/search_dataset_group"
    filename { "search-dataset-group-#{unique_id}" }
  end

  factory :opendata_node_search_dataset, class: Opendata::Node::SearchDataset, traits: [:cms_node] do
    route "opendata/search_dataset"
    filename { "search-dataset-#{unique_id}" }
  end

  factory :opendata_node_search_app, class: Opendata::Node::SearchApp, traits: [:cms_node] do
    route "opendata/search_app"
    filename { "search-app-#{unique_id}" }
  end

  factory :opendata_node_search_idea, class: Opendata::Node::SearchIdea, traits: [:cms_node] do
    route "opendata/search_idea"
    filename { "search-idea-#{unique_id}" }
  end

  factory :opendata_node_sparql, class: Opendata::Node::Sparql, traits: [:cms_node] do
    route "opendata/sparql"
    filename { "sparql-#{unique_id}" }
  end

  factory :opendata_node_api, class: Opendata::Node::Api, traits: [:cms_node] do
    route "opendata/api"
    filename { "api-#{unique_id}" }
  end

  factory :opendata_node_app, class: Opendata::Node::App, traits: [:cms_node] do
    route "opendata/app"
    filename { "app-#{unique_id}" }
  end

  factory :opendata_node_idea, class: Opendata::Node::Idea, traits: [:cms_node] do
    route "opendata/idea"
    filename { "idea-#{unique_id}" }
  end

  factory :opendata_node_mypage, class: Opendata::Node::Mypage, traits: [:cms_node] do
    route "opendata/mypage"
    filename { "mypage-#{unique_id}" }
  end

  factory :opendata_node_my_profile, class: Opendata::Node::MyProfile, traits: [:cms_node] do
    route "opendata/my_profile"
    filename { "myprofile-#{unique_id}" }
  end

  factory :opendata_node_my_dataset, class: Opendata::Node::MyDataset, traits: [:cms_node] do
    route "opendata/my_dataset"
    filename { "mydataset-#{unique_id}" }
  end

  factory :opendata_node_my_app, class: Opendata::Node::MyApp, traits: [:cms_node] do
    route "opendata/my_app"
    filename { "myapp-#{unique_id}" }
  end

  factory :opendata_node_my_idea, class: Opendata::Node::MyIdea, traits: [:cms_node] do
    route "opendata/my_idea"
    filename { "myidea-#{unique_id}" }
  end

  factory :opendata_node_member, class: Opendata::Node::Member, traits: [:cms_node] do
    route "opendata/member"
    filename { "member-#{unique_id}" }
  end
end
