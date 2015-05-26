require 'spec_helper'

describe "opendata_node_my_app", dbscope: :example do
  let(:site) { cms_site }
  let(:node_app) { create_once :opendata_node_app, name: "opendata_agents_nodes_appfile" }
  let(:app) { create_once :opendata_app, filename: "#{node_app.filename}/1.html" }

  let(:index_path) { opendata_node_apps_path(site) }
  let(:show_path) { opendata_node_app_path(site, app.id) }

  let!(:node_search) { create :opendata_node_search_app }
  let!(:node_auth) { create_once :opendata_node_mypage, basename: "opendata/mypage" }

  before do
    create_once :opendata_node_my_app, basename: "opendata/my_app"
    #login_opendata_member(site, node_auth)
  end

  context "with login" do
    it "#index" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        session.env("REQUEST_PATH", index_path)
        puts index_path.to_s
        visit index_path
        expect(current_path).to eq index_path
      end
    end

    it "#show" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        session.env("REQUEST_PATH", show_path)
        puts show_path.to_s
        visit show_path
        expect(current_path).to eq show_path
      end
    end
  end
end
