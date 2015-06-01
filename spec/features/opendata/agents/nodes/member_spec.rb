require 'spec_helper'

describe "opendata_agents_nodes_member", dbscope: :example do
  let(:site) { cms_site }
  let(:node_member) { create_once :opendata_node_member }
  let(:index_path) { "#{node_member.url}index.html" }

  describe "index" do
    it do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        expect { visit index_path }.to raise_error RuntimeError
      end
    end
  end

  describe "show and dataset" do
    let(:member) { opendata_member }
    let(:show_path) { "#{node_member.url}#{member.id}/" }
    it do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit show_path
        expect(page).to have_selector("article#cms-tab-#{member.id}-0")
        expect(page).to have_selector("article#cms-tab-#{member.id}-1")
        expect(page).to have_selector("article#cms-tab-#{member.id}-2")

        within "article#cms-tab-#{member.id}-0" do
          click_link "もっと見る"
        end
        expect(page).to have_selector("section.datasets")
      end
    end
  end

  describe "show and app" do
    let(:member) { opendata_member }
    let(:show_path) { "#{node_member.url}#{member.id}/" }
    it do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit show_path
        expect(page).to have_selector("article#cms-tab-#{member.id}-0")
        expect(page).to have_selector("article#cms-tab-#{member.id}-1")
        expect(page).to have_selector("article#cms-tab-#{member.id}-2")

        within "article#cms-tab-#{member.id}-1" do
          click_link "もっと見る"
        end
        expect(page).to have_selector("section.apps")
      end
    end
  end

  describe "show and idea" do
    let(:member) { opendata_member }
    let(:show_path) { "#{node_member.url}#{member.id}/" }
    it do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        visit show_path
        expect(page).to have_selector("article#cms-tab-#{member.id}-0")
        expect(page).to have_selector("article#cms-tab-#{member.id}-1")
        expect(page).to have_selector("article#cms-tab-#{member.id}-2")

        within "article#cms-tab-#{member.id}-2" do
          click_link "もっと見る"
        end
        expect(page).to have_selector("section.ideas")
      end
    end
  end
end
