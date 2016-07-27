FactoryGirl.define do
  factory :opendata_license, class: Opendata::License do
    transient do
      site nil
      user nil
      file nil
    end

    name { unique_id }
    site_id { site.present? ? site.id : nil }
    user_id { user.present? ? user.id : nil }
    in_file { file }
  end
end
