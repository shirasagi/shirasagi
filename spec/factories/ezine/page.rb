FactoryGirl.define do
  factory :ezine_page, class: Ezine::Page do
    cur_site { cms_site }
    cur_user { cms_user }
    route "ezine/page"
    name { unique_id }
    filename { "#{name}.html" }
    test_delivered nil
    completed false
  end
end
