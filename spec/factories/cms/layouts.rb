FactoryGirl.define do
  trait :cms_layout do
    site_id { create(:ss_site).id }
    user_id { create(:ss_user).id }
    name "#{unique_id}"
    filename "#{unique_id}.layout.html"
  end

  factory :cms_layout, class: Cms::Layout, traits: [:cms_layout] do
    #
  end
end
