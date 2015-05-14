FactoryGirl.define do
  factory :opendata_node_category, class: Opendata::Node::Category, traits: [:cms_node] do
    route "opendata/category"
  end

  factory :opendata_node_area, class: Opendata::Node::Area, traits: [:cms_node] do
    route "opendata/area"
  end

  factory :opendata_node_dataset, class: Opendata::Node::Dataset, traits: [:cms_node] do
    route "opendata/dataset"
  end

  factory :opendata_node_dataset_category, class: Opendata::Node::DatasetCategory, traits: [:cms_node] do
    route "opendata/dataset_category"
  end

  factory :opendata_node_search_dataset_group, class: Opendata::Node::SearchDatasetGroup, traits: [:cms_node] do
    route "opendata/search_dataset_group"
  end

  factory :opendata_node_search_dataset, class: Opendata::Node::SearchDataset, traits: [:cms_node] do
    route "opendata/search_dataset"
  end

  factory :opendata_node_search_app, class: Opendata::Node::SearchApp, traits: [:cms_node] do
    route "opendata/search_app"
  end

  factory :opendata_node_search_idea, class: Opendata::Node::SearchIdea, traits: [:cms_node] do
    route "opendata/search_idea"
  end

  factory :opendata_node_sparql, class: Opendata::Node::Sparql, traits: [:cms_node] do
    route "opendata/sparql"
  end

  factory :opendata_node_api, class: Opendata::Node::Api, traits: [:cms_node] do
    route "opendata/api"
  end

  factory :opendata_node_app, class: Opendata::Node::App, traits: [:cms_node] do
    route "opendata/app"
  end

  factory :opendata_node_idea, class: Opendata::Node::Idea, traits: [:cms_node] do
    route "opendata/idea"
  end

  factory :opendata_node_mypage, class: Opendata::Node::Mypage, traits: [:cms_node] do
    route "opendata/mypage"
  end

  factory :opendata_node_my_profile, class: Opendata::Node::MyProfile, traits: [:cms_node] do
    route "opendata/my_profile"
  end

  factory :opendata_node_my_dataset, class: Opendata::Node::MyDataset, traits: [:cms_node] do
    route "opendata/my_dataset"
  end

  factory :opendata_node_my_app, class: Opendata::Node::MyApp, traits: [:cms_node] do
    route "opendata/my_app"
  end

  factory :opendata_node_my_idea, class: Opendata::Node::MyIdea, traits: [:cms_node] do
    route "opendata/my_idea"
  end

  factory :opendata_node_member, class: Opendata::Node::Member, traits: [:cms_node] do
    route "opendata/member"
  end
end
