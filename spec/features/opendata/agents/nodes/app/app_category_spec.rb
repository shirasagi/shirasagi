require 'spec_helper'

describe "opendata_agents_nodes_app_category", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node_category_root) { create :cms_node_node, cur_site: site, layout_id: layout.id }
  let(:node_category1) do
    create(
      :opendata_node_category,
      cur_site: site,
      cur_node: node_category_root,
      layout_id: layout.id,
      filename: "kurashi",
      depth: node_category_root.depth + 1)
  end
  let(:node_app) { create :opendata_node_app, cur_site: site, layout_id: layout.id }
  let(:node) do
    create(
      :opendata_node_app_category,
      cur_site: site,
      cur_node: node_app,
      layout_id: layout.id,
      name: "opendata_agents_nodes_app_category",
      filename: "#{node_category_root.filename}",
      depth: node_app.depth + 1)
  end
  let(:node_area) { create :opendata_node_area, cur_site: site, layout_id: layout.id }
  let(:app) { create :opendata_app, cur_site: site, cur_node: node_app, layout_id: layout.id, area_ids: [ node_area.id ], category_ids: [ node_category1.id ] }
  before do
    create(:opendata_node_search_app, cur_site: site, cur_node: node_app, layout_id: layout.id)

    Fs::UploadedFile.create_from_file(Rails.root.join("spec", "fixtures", "opendata", "index.html"), basename: "spec") do |file|
      create_appfile(app, file, "HTML")
    end
    Fs::UploadedFile.create_from_file(Rails.root.join("spec", "fixtures", "opendata", "test.js"), basename: "spec") do |file|
      create_appfile(app, file, "JS")
    end
    Fs::UploadedFile.create_from_file(Rails.root.join("spec", "fixtures", "opendata", "test.css"), basename: "spec") do |file|
      create_appfile(app, file, "CSS")
    end
  end

  def create_appfile(app, file, format)
    appfile = app.appfiles.new(text: "index", format: format)
    appfile.in_file = file
    appfile.save
    appfile
  end

  let(:index_path) { "#{node.url}kurashi" }
  let(:rss_path) { "#{node.url}kurashi/rss.xml" }

  it "#index" do
    visit index_path
    expect(current_path).to eq index_path
    expect(page).to have_css(".app-count .count", text: "1")

    expect(page).to have_css(".opendata-tabs .names a.tab-released", text: "新着順")
    expect(page).to have_css(".opendata-tabs .names a.tab-popular", text: "人気順")
    expect(page).to have_css(".opendata-tabs .names a.tab-attention", text: "注目順")

    expect(page).to have_css(".opendata-tabs .tab-released h2", text: "新着順", visible: false)
    expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: app.name)
    expect(page).to have_css(".opendata-tabs .tab-released .pages h2 .point", text: app.point.to_s)
    expect(page).to have_css(".opendata-tabs .tab-popular h2", text: "人気順", visible: false)
    expect(page).to have_css(".opendata-tabs .tab-popular .pages h2 a", text: app.name, visible: false)
    expect(page).to have_css(".opendata-tabs .tab-popular .pages h2 .point", text: app.point.to_s, visible: false)
    expect(page).to have_css(".opendata-tabs .tab-attention h2", text: "注目順", visible: false)
    expect(page).to have_css(".opendata-tabs .tab-attention .pages h2 a", text: app.name, visible: false)
    expect(page).to have_css(".opendata-tabs .tab-attention .pages h2 .point", text: app.point.to_s, visible: false)
    expect(page).to have_css(".areas .name", text: node_area.name)
    expect(page).to have_css(".tags .name", text: app.tags[0])
    expect(page).to have_css(".tags .name", text: app.tags[1])
    licenses = Opendata::App.aggregate_field(:license, limit: 10)
    expect(page).to have_css(".licenses .name", text: licenses.first["id"])
  end

  it "#rss" do
    visit rss_path
    expect(current_path).to eq rss_path
    expect(page.response_headers['Content-Type']).to include("application/rss+xml")
  end

  context "when point is hide" do
    before do
      node_app.show_point = 'hide'
      node_app.save!

      app.touch
      app.save!
    end

    it do
      visit index_path
      expect(page).to have_css(".opendata-tabs .tab-released h2", text: "新着順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: app.name)
      expect(page).not_to have_css(".opendata-tabs .tab-released .pages h2 .point", text: app.point.to_s, visible: false)
      expect(page).to have_css(".opendata-tabs .tab-popular h2", text: "人気順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-popular .pages h2 a", text: app.name, visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-popular .pages h2 .point", text: app.point.to_s, visible: false)
      expect(page).to have_css(".opendata-tabs .tab-attention h2", text: "注目順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-attention .pages h2 a", text: app.name, visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-attention .pages h2 .point", text: app.point.to_s, visible: false)
    end
  end

  context "when only released is enabled" do
    before do
      node_app.show_tabs = 'released'
      node_app.save!

      app.touch
      app.save!
    end

    it do
      visit index_path
      expect(page).not_to have_css(".opendata-tabs .names", visible: false)

      expect(page).to have_css(".opendata-tabs .tab-released h2", text: "新着順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: app.name)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 .point", text: app.point.to_s, visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-popular", visible: false)
      expect(page).not_to have_css(".opendata-tabs .tab-attention", text: "注目順", visible: false)
    end
  end
end
