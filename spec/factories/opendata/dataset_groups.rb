FactoryGirl.define do
  factory :opendata_dataset_group, class: Opendata::DatasetGroup do
    transient do
      site nil
      user nil
      categories nil
    end

    name { "#{unique_id}" }
    site_id { site.present? ? site.id : nil }
    user_id { user.present? ? user.id : nil }
    category_ids { categories.present? ? categories.map(&:_id) : nil }
  end
end
