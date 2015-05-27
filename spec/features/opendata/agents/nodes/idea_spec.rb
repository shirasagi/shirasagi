require 'spec_helper'

describe "opendata_agents_nodes_idea", dbscope: :example do

  before do
    create_once :opendata_node_search_idea, basename: "idea/search"
  end

  let(:site) { cms_site }
  let(:area) { create_once :opendata_node_area, basename: "opendata_area_1" }
  let(:node_idea) { create_once :opendata_node_idea }
  let!(:node_area) { create :opendata_node_area, name: '地域Ａ' }

  let(:page_idea) { create_once :opendata_idea, filename: "#{node_idea.filename}/1.html", area_ids: [ area.id ] }
  let(:index_path) { "#{node_idea.url}index.html" }
  let(:show_point_path) { "#{node_idea.url}#{page_idea.id}/point.html" }
  let(:add_point_path) { "#{node_idea.url}#{page_idea.id}/point.html" }
  let(:point_members_path) { "#{node_idea.url}#{page_idea.id}/point/members.html" }
  let(:show_comment_path) { "#{node_idea.url}#{page_idea.id}/comment/show.html" }
  let(:show_dataset_path) { "#{node_idea.url}#{page_idea.id}/dataset/show.html" }
  let(:show_app_path) { "#{node_idea.url}#{page_idea.id}/app/show.html" }
  let(:rss_path) { "#{node_idea.url}rss.xml" }
  let(:areas_path) { "#{node_idea.url}areas.html" }
  let(:tags_path) { "#{node_idea.url}tags.html" }

  it "#index" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", index_path)
      visit index_path
      expect(current_path).to eq index_path
    end
  end

  it "#show_point" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", show_point_path)
#      session.env("method", "POST")
      visit show_point_path
      expect(current_path).to eq show_point_path
    end
  end

  it "#rss" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", rss_path)
      visit rss_path
      expect(current_path).to eq rss_path
    end
  end

  it "#areas" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", areas_path)
      visit areas_path
      expect(current_path).to eq areas_path
      #expect(page).to have_content(node_area.name)
    end
  end

  it "#tags" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", tags_path)
      visit tags_path
      expect(current_path).to eq tags_path
      #expect(page).to have_content(page_idea.tags[0])
      #expect(page).to have_content(page_idea.tags[1])
    end
  end

  it "#point_members" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", point_members_path)
      visit point_members_path
      expect(current_path).to eq point_members_path
    end
  end

  it "#show_comment" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", show_comment_path)
      visit show_comment_path
      expect(current_path).to eq show_comment_path
    end
  end

  it "#show_dataset" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", show_dataset_path)
      visit show_dataset_path
      expect(current_path).to eq show_dataset_path
    end
  end

  it "#show_app" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", show_app_path)
      visit show_app_path
      expect(current_path).to eq show_app_path
    end
  end

end
