require 'spec_helper'

describe "opendata_agents_nodes_idea_category", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node_category_folder) { create :cms_node_node, cur_site: site, layout_id: layout.id, basename: "category" }
  let(:node_idea) { create :opendata_node_idea, cur_site: site, layout_id: layout.id }
  let(:node_area) { create :opendata_node_area, cur_site: site, layout_id: layout.id }
  let(:node) do
    create(
      :opendata_node_idea_category,
      cur_site: site,
      cur_node: node_idea,
      layout_id: layout.id,
      basename: node_category_folder.filename,
      name: "opendata_agents_nodes_idea_category")
  end
  let!(:node_cate) do
    create(
      :opendata_node_category,
      cur_site: site,
      cur_node: node_category_folder,
      layout_id: layout.id,
      basename: "kurashi")
  end
  let!(:node_search_idea) do
    create(
      :opendata_node_search_idea,
      cur_site: site,
      cur_node: node_idea,
      layout_id: layout.id,
      basename: "search")
  end
  let!(:page_idea) do
    create(
      :opendata_idea,
      cur_site: site,
      cur_node: node_idea,
      layout_id: layout.id,
      filename: "1.html",
      area_ids: [ node_area.id ],
      category_ids: [ node_cate.id ])
  end

  let(:index_path) { "#{node.url}kurashi" }
  let(:rss_path) { "#{node.url}kurashi/rss.xml" }
  let(:nothing_path) { "#{node.url}index.html" }

  it "#index" do
    visit index_path
    expect(current_path).to eq index_path
    expect(page).to have_css(".idea-count .count", text: "1")

    expect(page).to have_css(".opendata-tabs .names a.tab-released", text: "新着順")
    expect(page).to have_css(".opendata-tabs .names a.tab-popular", text: "人気順")
    expect(page).to have_css(".opendata-tabs .names a.tab-attention", text: "注目順")

    expect(page).to have_css(".opendata-tabs .tab-released h2", text: "新着順", visible: false)
    expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: page_idea.name)
    expect(page).to have_css(".opendata-tabs .tab-released .pages h2 .point", text: page_idea.point.to_s)
    expect(page).to have_css(".opendata-tabs .tab-popular h2", text: "人気順", visible: false)
    expect(page).to have_css(".opendata-tabs .tab-popular .pages h2 a", text: page_idea.name, visible: false)
    expect(page).to have_css(".opendata-tabs .tab-popular .pages h2 .point", text: page_idea.point.to_s, visible: false)
    expect(page).to have_css(".opendata-tabs .tab-attention h2", text: "注目順", visible: false)
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

  it "#nothing" do
    visit nothing_path
    expect(current_path).to eq nothing_path
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
      expect(page).to have_css(".opendata-tabs .tab-released h2", text: "新着順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: page_idea.name)
      expect(page).not_to have_css(".opendata-tabs .tab-released .pages h2 .point", text: page_idea.point.to_s, visible: false)
      expect(page).to have_css(".opendata-tabs .tab-popular h2", text: "人気順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-popular .pages h2 a", text: page_idea.name, visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-popular .pages h2 .point", text: page_idea.point.to_s, visible: false)
      expect(page).to have_css(".opendata-tabs .tab-attention h2", text: "注目順", visible: false)
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

      expect(page).to have_css(".opendata-tabs .tab-released h2", text: "新着順", visible: false)
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

      expect(page).to have_css(".opendata-tabs .tab-released h2", text: "アイデア一覧", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: page_idea.name)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 .point", text: page_idea.point.to_s, visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-popular", visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-attention", text: "注目順", visible: false)
    end
  end
end
