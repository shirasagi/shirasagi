FactoryGirl.define do
  factory :opendata_part_mypage_login, class: Opendata::Part::MypageLogin, traits: [:cms_part] do
    route "opendata/mypage_login"
  end

  factory :opendata_part_dataset, class: Opendata::Part::Dataset, traits: [:cms_part] do
    route "opendata/dataset"
  end

  factory :opendata_part_dataset_group, class: Opendata::Part::DatasetGroup, traits: [:cms_part] do
    route "opendata/dataset_group"
  end

  factory :opendata_part_app, class: Opendata::Part::App, traits: [:cms_part] do
    route "opendata/app"
  end

  factory :opendata_part_idea, class: Opendata::Part::Idea, traits: [:cms_part] do
    route "opendata/idea"
  end
end
