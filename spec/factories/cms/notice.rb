FactoryGirl.define do
  factory :cms_notice, class: Cms::Notice do
    transient do
      site nil
    end

    cur_site { site ? site : cms_site }
    name { "name-#{unique_id}" }
  end
end
