require 'spec_helper'

describe "opendata_agents_nodes_member", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node_member) { create :opendata_node_member, layout_id: layout.id }
  let(:member) { opendata_member }
  let(:show_path) { "#{node_member.full_url}#{member.id}/" }

  describe "show and dataset" do
    let(:member) { opendata_member }

    it do
      visit show_path
      expect(page).to have_selector("a#cms-tab-#{member.id}-0-name", text: 'データセット')
      expect(page).to have_selector("a#cms-tab-#{member.id}-1-name", text: 'アプリ')
      expect(page).to have_selector("a#cms-tab-#{member.id}-2-name", text: 'アイデア')
      expect(page).to have_selector("article#cms-tab-#{member.id}-0-view")
      expect(page).to have_selector("article#cms-tab-#{member.id}-1-view")
      expect(page).to have_selector("article#cms-tab-#{member.id}-2-view")

      within "article#cms-tab-#{member.id}-0-view" do
        click_link "もっと見る"
      end
      expect(page).to have_selector("section.datasets")
    end
  end

  describe "show and app" do
    it do
      visit show_path
      expect(page).to have_selector("a#cms-tab-#{member.id}-0-name", text: 'データセット')
      expect(page).to have_selector("a#cms-tab-#{member.id}-1-name", text: 'アプリ')
      expect(page).to have_selector("a#cms-tab-#{member.id}-2-name", text: 'アイデア')
      expect(page).to have_selector("article#cms-tab-#{member.id}-0-view")
      expect(page).to have_selector("article#cms-tab-#{member.id}-1-view")
      expect(page).to have_selector("article#cms-tab-#{member.id}-2-view")

      find("a#cms-tab-#{member.id}-1-name").click
      within "article#cms-tab-#{member.id}-1-view" do
        click_link "もっと見る"
      end
      expect(page).to have_selector("section.apps")
    end
  end

  describe "show and idea" do
    it do
      visit show_path
      expect(page).to have_selector("a#cms-tab-#{member.id}-0-name", text: 'データセット')
      expect(page).to have_selector("a#cms-tab-#{member.id}-1-name", text: 'アプリ')
      expect(page).to have_selector("a#cms-tab-#{member.id}-2-name", text: 'アイデア')
      expect(page).to have_selector("article#cms-tab-#{member.id}-0-view")
      expect(page).to have_selector("article#cms-tab-#{member.id}-1-view")
      expect(page).to have_selector("article#cms-tab-#{member.id}-2-view")

      find("a#cms-tab-#{member.id}-2-name").click
      within "article#cms-tab-#{member.id}-2-view" do
        click_link "もっと見る"
      end
      expect(page).to have_selector("section.ideas")
    end
  end

  context "when dataset is disabled" do
    before do
      site.dataset_state = 'disabled'
      site.save!
    end

    it do
      visit show_path
      expect(page).not_to have_selector("a#cms-tab-#{member.id}-0-name")
      expect(page).to     have_selector("a#cms-tab-#{member.id}-1-name", text: 'アプリ')
      expect(page).to     have_selector("a#cms-tab-#{member.id}-2-name", text: 'アイデア')
    end
  end

  context "when app is disabled" do
    before do
      site.app_state = 'disabled'
      site.save!
    end

    it do
      visit show_path
      expect(page).to     have_selector("a#cms-tab-#{member.id}-0-name", text: 'データセット')
      expect(page).not_to have_selector("a#cms-tab-#{member.id}-1-name")
      expect(page).to     have_selector("a#cms-tab-#{member.id}-2-name", text: 'アイデア')
    end
  end

  context "when idea is disabled" do
    before do
      site.idea_state = 'disabled'
      site.save!
    end

    it do
      visit show_path
      expect(page).to     have_selector("a#cms-tab-#{member.id}-0-name", text: 'データセット')
      expect(page).to     have_selector("a#cms-tab-#{member.id}-1-name", text: 'アプリ')
      expect(page).not_to have_selector("a#cms-tab-#{member.id}-2-name")
    end
  end
end
