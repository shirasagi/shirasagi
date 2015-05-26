require 'spec_helper'

describe "opendata_agents_nodes_my_app", dbscope: :example do
  let(:site) { cms_site }

  let!(:node_mypage) { create_once :opendata_node_mypage, filename: "mypage" }
  let!(:node_myapp) { create_once :opendata_node_my_app, filename: "#{node_mypage.filename}/myapp" }

  let(:category) { create_once :opendata_node_category, basename: "opendata_category1" }
  let(:area) { create_once :opendata_node_area, basename: "opendata_area_1" }
  let(:node_app) { create_once :opendata_node_app, name: "opendata_app" }

  let(:app) do
    create_once :opendata_app,
      filename: "#{node_app.filename}/1.html",
      category_ids: [ category.id ],
      area_ids: [ area.id ]
  end
  #let(:app) { create_once :opendata_app, filename: "#{node_app.filename}/1.html" }
  #let(:app) { create(:opendata_app, node: node_app) }

  let!(:node_search) { create :opendata_node_search_app }
  let!(:node_auth) { create_once :opendata_node_mypage, basename: "opendata/mypage" }

  let(:index_path) { "#{node_myapp.url}index.html" }
  let(:show_path) { "#{node_myapp.url}#{app.id}" }

  before do
    login_opendata_member(site, node_auth)
  end

  it "#index" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", index_path)
      session.env("HTTP_USER_AGENT", "user_agent")
      visit "http://#{site.domain}#{index_path}"
      expect(current_path).to eq index_path
    end
  end

  it "#show" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", show_path)
      session.env("HTTP_USER_AGENT", "user_agent")
      visit "http://#{site.domain}#{show_path}"
      expect(current_path).to eq show_path
    end
  end
end
