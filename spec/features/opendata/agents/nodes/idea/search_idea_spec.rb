require 'spec_helper'

describe "opendata_search_ideas", dbscope: :example do
  let(:site) { cms_site }
  let(:node_idea) { create_once :opendata_node_idea }
  let(:node) do
    create_once(
      :opendata_node_search_idea,
      basename: "#{node_idea.filename}/search",
      depth: node_idea.depth + 1,
      name: "opendata_search_ideas")
  end

  let(:index_path) { "#{node.url}index.html" }
  let(:rss_path) { "#{node.url}rss.xml" }
  let!(:node_category_folder) { create_once(:cms_node_node, basename: "category") }
  let!(:node_category) do
    create_once(
      :opendata_node_category,
      basename: "#{node_category_folder.filename}/kurashi",
      depth: node_category_folder.depth + 1,
      name: 'カテゴリー０１')
  end
  let!(:node_area) { create_once :opendata_node_area, name: '地域Ａ' }

  context "search_idea" do

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

    it "#keyword_input" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)

        visit index_path
        fill_in "s_keyword", with: "アイデア"
        click_button "検索"
        expect(status_code).to eq 200
      end
    end

    it "#category_select" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)

        visit index_path
        # page.save_page
        select node_category.name
        click_button "検索"
        expect(status_code).to eq 200
      end
    end

    it "#area_select" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)

        visit index_path
        select node_area.name
        click_button "検索"
        expect(status_code).to eq 200
      end
    end

    it "#tag_input" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)

        visit index_path
        fill_in "s_tag", with: "テスト"
        click_button "検索"
        expect(status_code).to eq 200
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
