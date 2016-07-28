FactoryGirl.define do
  factory :opendata_dataset_group, class: Opendata::DatasetGroup do
    transient do
      categories nil
    end

    name { unique_id }
    cur_site { cms_site }
    category_ids { categories.present? ? categories.map(&:_id).to_a : nil }
  end
end
