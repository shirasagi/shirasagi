FactoryGirl.define do
  factory :opendata_member, class: Opendata::Member do
    transient do
      site nil
      icon_file nil
    end

    site_id { site.present? ? site.id : cms_site.id }
    name { "#{unique_id}" }
    email { "#{name}@example.jp" }
    in_password "pass"
    in_icon { icon_file.present? ? icon_file : nil }
  end
end
