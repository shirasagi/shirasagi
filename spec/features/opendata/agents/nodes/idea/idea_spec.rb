require 'spec_helper'

describe "opendata_agents_nodes_idea", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node_idea) { create :opendata_node_idea, cur_site: site, layout_id: layout.id }
  let!(:node_member) { create :opendata_node_member, cur_site: site, layout_id: layout.id }
  let!(:node_mypage) { create :opendata_node_mypage, cur_site: site, layout_id: layout.id, filename: "mypage" }
  let!(:node_login) { create :member_node_login, cur_site: site, layout_id: layout.id, redirect_url: node_idea.url }

  let!(:node_area) { create :opendata_node_area, cur_site: site, layout_id: layout.id }
  let!(:node_idea_search) { create :opendata_node_search_idea, cur_site: site, cur_node: node_idea, layout_id: layout.id }

  let!(:page_idea) { create :opendata_idea, cur_site: site, cur_node: node_idea, layout_id: layout.id, filename: "1.html", area_ids: [ node_area.id ] }
  let(:index_path) { "#{node_idea.url}index.html" }
  let(:rss_path) { "#{node_idea.url}rss.xml" }
  let(:areas_path) { "#{node_idea.url}areas.html" }
  let(:tags_path) { "#{node_idea.url}tags.html" }

  context "without login" do
    it "#index" do
      visit index_path
      expect(current_path).to eq index_path
      expect(page).to have_css(".idea-count .count", text: "1")

      expect(page).to have_css(".opendata-tabs .names a.tab-released", text: "新着順")
      expect(page).to have_css(".opendata-tabs .names a.tab-popular", text: "人気順")
      expect(page).to have_css(".opendata-tabs .names a.tab-attention", text: "注目順")

      expect(page).to have_css(".opendata-tabs .tab-released h1", text: "新着順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: page_idea.name)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 .point", text: page_idea.point.to_s)
      expect(page).to have_css(".opendata-tabs .tab-popular h1", text: "人気順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-popular .pages h2 a", text: page_idea.name, visible: false)
      expect(page).to have_css(".opendata-tabs .tab-popular .pages h2 .point", text: page_idea.point.to_s, visible: false)
      expect(page).to have_css(".opendata-tabs .tab-attention h1", text: "注目順", visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-attention .pages h2 a", text: page_idea.name, visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-attention .pages h2 .point", text: page_idea.point.to_s, visible: false)
      expect(page).to have_css(".areas .name", text: node_area.name)
      expect(page).to have_css(".tags .name", text: page_idea.tags[0])
      expect(page).to have_css(".tags .name", text: page_idea.tags[1])
    end

    it "#rss" do
      visit rss_path
      expect(current_path).to eq rss_path
    end

    it "#areas" do
      visit areas_path
      expect(current_path).to eq areas_path
      expect(page).to have_css('article header h2 .name', text: node_area.name)
      expect(page).to have_css('article header h2 .count', text: '(1)')
    end

    it "#tags" do
      visit tags_path
      expect(current_path).to eq tags_path
      expect(page).to have_css('article header h2 .name', text: page_idea.tags[0])
      expect(page).to have_css('article header h2 .name', text: page_idea.tags[1])
    end
  end

  context "with login" do
    before do
      login_opendata_member(site, node_login)
    end

    after do
      logout_opendata_member(site, node_login)
    end

    it "#index" do
      visit index_path
      expect(current_path).to eq index_path
      expect(page).to have_css(".idea-count .count", text: "1")

      expect(page).to have_css(".opendata-tabs .names a.tab-released", text: "新着順")
      expect(page).to have_css(".opendata-tabs .names a.tab-popular", text: "人気順")
      expect(page).to have_css(".opendata-tabs .names a.tab-attention", text: "注目順")

      expect(page).to have_css(".opendata-tabs .tab-released h1", text: "新着順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: page_idea.name)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 .point", text: page_idea.point.to_s)
      expect(page).to have_css(".opendata-tabs .tab-popular h1", text: "人気順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-popular .pages h2 a", text: page_idea.name, visible: false)
      expect(page).to have_css(".opendata-tabs .tab-popular .pages h2 .point", text: page_idea.point.to_s, visible: false)
      expect(page).to have_css(".opendata-tabs .tab-attention h1", text: "注目順", visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-attention .pages h2 a", text: page_idea.name, visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-attention .pages h2 .point", text: page_idea.point.to_s, visible: false)
      expect(page).to have_css(".areas .name", text: node_area.name)
      expect(page).to have_css(".tags .name", text: page_idea.tags[0])
      expect(page).to have_css(".tags .name", text: page_idea.tags[1])

      within "article.tab-released" do
        click_on page_idea.name
      end

      expect(page).to have_css(".count .number", text: "1")
      within "div.like" do
        click_on "いいね！"
      end
      expect(page).to have_css(".count .number", text: "2")

      within ".count .label" do
        click_on "いいね！"
      end
      expect(page).to have_css(".point-members")
    end

    it "#rss" do
      visit rss_path
      expect(current_path).to eq rss_path
    end

    it "#areas" do
      visit areas_path
      expect(current_path).to eq areas_path
      expect(page).to have_css('article header h2 .name', text: node_area.name)
      expect(page).to have_css('article header h2 .count', text: '(1)')
    end

    it "#tags" do
      visit tags_path
      expect(current_path).to eq tags_path
      expect(page).to have_css('article header h2 .name', text: page_idea.tags[0])
      expect(page).to have_css('article header h2 .name', text: page_idea.tags[1])
    end
  end

  context "when point is hide" do
    before do
      node_idea.show_point = 'hide'
      node_idea.save!

      page_idea.touch
      page_idea.save!
    end

    it do
      visit index_path
      expect(page).to have_css(".opendata-tabs .tab-released h1", text: "新着順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: page_idea.name)
      expect(page).not_to have_css(".opendata-tabs .tab-released .pages h2 .point", text: page_idea.point.to_s, visible: false)
      expect(page).to have_css(".opendata-tabs .tab-popular h1", text: "人気順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-popular .pages h2 a", text: page_idea.name, visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-popular .pages h2 .point", text: page_idea.point.to_s, visible: false)
      expect(page).to have_css(".opendata-tabs .tab-attention h1", text: "注目順", visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-attention .pages h2 a", text: page_idea.name, visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-attention .pages h2 .point", text: page_idea.point.to_s, visible: false)
    end
  end

  context "when only released is enabled" do
    before do
      node_idea.show_tabs = 'released'
      node_idea.save!

      page_idea.touch
      page_idea.save!
    end

    it do
      visit index_path
      expect(page).not_to have_css(".opendata-tabs .names", visible: false)

      expect(page).to have_css(".opendata-tabs .tab-released h1", text: "新着順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: page_idea.name)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 .point", text: page_idea.point.to_s, visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-popular", visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-attention", text: "注目順", visible: false)
    end
  end

  context "when only released is enabled and tab title is renamed" do
    before do
      node_idea.show_tabs = 'released'
      node_idea.tab_titles = { 'released' => 'アイデア一覧' }
      node_idea.save!

      page_idea.touch
      page_idea.save!
    end

    it do
      visit index_path
      expect(page).not_to have_css(".opendata-tabs .names", visible: false)

      expect(page).to have_css(".opendata-tabs .tab-released h1", text: "アイデア一覧", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: page_idea.name)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 .point", text: page_idea.point.to_s, visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-popular", visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-attention", text: "注目順", visible: false)
    end
  end
end
