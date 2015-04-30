FactoryGirl.define do
  factory :ezine_page, class: Ezine::Page do
    site_id { cms_site.id }
    user_id { cms_user.id }
    name 'title'
    filename 'magazine/1'
    test_delivered nil
    completed false
  end
end
