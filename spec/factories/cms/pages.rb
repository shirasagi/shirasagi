FactoryGirl.define do
  trait :cms_page do
    site_id { create(:ss_site).id }
    user_id { create(:ss_user).id }
    name "#{unique_id}"
    filename "#{unique_id}.html"
    route "cms/page"
  end

  factory :cms_page, class: Cms::Page, traits: [:cms_page] do
    #
  end
end
