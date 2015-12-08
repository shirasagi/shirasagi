require 'spec_helper'

describe "opendata_search_apps", dbscope: :example do
  let(:site) { cms_site }
  let(:node_app) { create_once :opendata_node_app }
  let(:node) do
    create_once(
      :opendata_node_search_app,
      basename: "#{node_app.filename}/search",
      depth: node_app.depth + 1,
      name: "opendata_search_apps")
  end
  before do
    node_category_folder = create_once(:cms_node_node, basename: "category")
    create_once(
      :opendata_node_category,
      basename: "#{node_category_folder.filename}/kurashi",
      depth: node_category_folder.depth + 1)
  end

  let(:index_path) { "#{node.url}index.html" }
  let(:rss_path) { "#{node.url}rss.xml" }

  context "search_app" do
    it "#index" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit index_path
        expect(current_path).to eq index_path
      end
    end

    it "#index released" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit "#{index_path}?&sort=released"
        expect(current_path).to eq index_path
      end
    end

    it "#index popular" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit "#{index_path}?&sort=popular"
        expect(current_path).to eq index_path
      end
    end

    it "#index attention" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit "#{index_path}?&sort=attention"
        expect(current_path).to eq index_path
      end
    end

    it "#rss" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit rss_path
        expect(current_path).to eq rss_path
      end
    end
  end
end
