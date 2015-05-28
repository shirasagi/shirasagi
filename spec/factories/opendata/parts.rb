FactoryGirl.define do
  factory :opendata_part_mypage_login, class: Opendata::Part::MypageLogin, traits: [:cms_part] do
    transient do
      node nil
    end

    route "opendata/mypage_login"
    filename { node.blank? ? "#{name}.part.html" : "#{node.filename}/#{name}.part.html" }
  end

  factory :opendata_part_dataset, class: Opendata::Part::Dataset, traits: [:cms_part] do
    transient do
      node nil
    end

    route "opendata/dataset"
    filename { node.blank? ? "#{name}.part.html" : "#{node.filename}/#{name}.part.html" }
  end

  factory :opendata_part_dataset_group, class: Opendata::Part::DatasetGroup, traits: [:cms_part] do
    transient do
      node nil
    end

    route "opendata/dataset_group"
    filename { node.blank? ? "#{name}.part.html" : "#{node.filename}/#{name}.part.html" }
  end

  factory :opendata_part_app, class: Opendata::Part::App, traits: [:cms_part] do
    transient do
      node nil
    end

    route "opendata/app"
    filename { node.blank? ? "#{name}.part.html" : "#{node.filename}/#{name}.part.html" }
  end

  factory :opendata_part_idea, class: Opendata::Part::Idea, traits: [:cms_part] do
    transient do
      node nil
    end

    route "opendata/idea"
    filename { node.blank? ? "#{name}.part.html" : "#{node.filename}/#{name}.part.html" }
  end
end
