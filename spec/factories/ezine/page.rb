FactoryGirl.define do
  factory :ezine_page, class: Ezine::Page do
    cur_site { cms_site }
    cur_user { cms_user }
    name 'title'
    filename 'magazine/page'
    text 'text'
    html 'html'
    test_delivered nil
    completed false
  end
end
