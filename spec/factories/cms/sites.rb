FactoryBot.define do
  factory :cms_site, class: Cms::Site do
    name "Site"
    host "test"
    domains { (server = Capybara.current_session.server).nil? ? "test.localhost.jp" : "#{server.host}:#{server.port}" }
    auto_keywords "disabled"
    auto_description "disabled"
    #group_id 1
  end

  factory :cms_site_subdir, class: Cms::Site do
    name { unique_id }
    host { name }
    domains { (server = Capybara.current_session.server).nil? ? "#{name}.localhost.jp" : "#{server.host}:#{server.port}" }
    auto_keywords "disabled"
    auto_description "disabled"
    subdir { unique_id }
  end
end
