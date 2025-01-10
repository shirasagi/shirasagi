require 'spec_helper'

describe "opendata_agents_nodes_app", type: :feature, dbscope: :example, js: true do
  def create_appfile(app, file, format)
    appfile = app.appfiles.new(text: "aaa", format: format)
    appfile.in_file = file
    appfile.save!

    ::FileUtils.rm_f(app.path)

    appfile
  end

  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node) { create :opendata_node_app, cur_site: cms_site, layout_id: layout.id }
  let!(:node_idea) { create :opendata_node_idea, cur_site: cms_site, layout_id: layout.id }
  let!(:node_member) { create :opendata_node_member, cur_site: cms_site, layout_id: layout.id }
  let!(:node_mypage) { create :opendata_node_mypage, cur_site: cms_site, layout_id: layout.id, filename: "mypage" }
  let!(:node_myidea) do
    create :opendata_node_my_idea, cur_site: cms_site, cur_node: node_mypage, layout_id: layout.id, filename: "idea"
  end

  let!(:node_search) { create :opendata_node_search_app, cur_site: cms_site, layout_id: layout.id }

  let!(:node_login) { create :member_node_login, cur_site: cms_site, layout_id: layout.id, redirect_url: node.url }

  let!(:area) { create :opendata_node_area, cur_site: cms_site, layout_id: layout.id }
  let!(:app) { create :opendata_app, cur_site: cms_site, cur_node: node, layout_id: layout.id, area_ids: [ area.id ] }

  let(:index_path) { "#{node.url}index.html" }
  let(:download_path) { "#{node.url}#{app.id}/zip" }
  let(:show_point_path) { "#{node.url}#{app.id}/point.html" }
  let(:point_members_path) { "#{node.url}#{app.id}/point/members.html" }
  let(:rss_path) { "#{node.url}rss.xml" }
  let(:show_ideas_path) { "/#{app.filename.sub('.html', '')}/ideas/show.html" }
  let(:index_areas_path) { "#{node.url}areas.html" }
  let(:index_tags_path) { "#{node.url}tags.html" }
  let(:index_licenses_path) { "#{node.url}licenses.html" }

  let(:file_index_path) { Rails.root.join("spec", "fixtures", "opendata", "index.html") }
  let(:file_index) { Fs::UploadedFile.create_from_file(file_index_path, basename: "spec") }
  let!(:appfile) { create_appfile(app, file_index, "HTML") }
  let(:full_path) { "/#{app.filename.sub('.html', '')}/full/index.html" }
  let(:app_index_path) { "/#{app.filename.sub('.html', '')}/file_index/index.html" }
  let(:text_path) { "/#{app.filename.sub('.html', '')}/file_text/index.html" }

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
    expect(page).to have_css(".areas .name", text: area.name)
    expect(page).to have_css(".tags .name", text: app.tags[0])
    expect(page).to have_css(".tags .name", text: app.tags[1])
    licenses = Opendata::App.aggregate_field(:license, limit: 10)
    expect(page).to have_css(".licenses .name", text: licenses.first["id"])
  end

  context "#download" do
    before do
      clear_downloads
    end

    after do
      clear_downloads
    end

    it do
      visit index_path
      within "article.tab-released" do
        click_on app.name
      end
      expect(page).to have_css("#executed", text: "1 #{I18n.t("opendata.labels.time")}")
      click_on I18n.t("opendata.search_datasets.bluk_download")

      wait_for_download

      entry_count = 0
      Zip::File.open(downloads.first) do |archive|
        archive.each do |_entry|
          entry_count += 1
        end
      end
      expect(entry_count).to be > 0
    end
  end

  it "#rss" do
    layout.html = <<~HTML
      <html>
      <body>
        <br><br><br>
        <h1 id="ss-page-name">\#{page_name}</h1><br>
        <div id="main" class="page">
          {{ yield }}
          <div class="list-footer">
            <a href="#{rss_path}" download>RSS</a>
          </div>
        </div>
      </body>
      </html>
    HTML
    layout.save!

    visit index_path
    within ".list-footer" do
      click_on "RSS"
    end

    wait_for_download
    ::File.read(downloads.first).tap do |xml|
      xmldoc = REXML::Document.new(xml)
      items = REXML::XPath.match(xmldoc, "/rss/channel/item")
      expect(items).to have(1).items
    end
  end

  it "#show_ideas" do
    visit show_ideas_path
    expect(current_path).to eq show_ideas_path
    expect(page).to have_css(".app-ideas")
  end

  it "#full" do
    visit full_path
    expect(current_path).to eq full_path
    expect(page).to have_css(".app-body iframe")
  end

  it "#app_index" do
    visit app_index_path
    expect(current_path).to eq app_index_path
    expect(page).to have_css("body p", text: "test")
  end

  it "#text" do
    visit text_path
    expect(current_path).to eq text_path
    expect(page).to have_css("body pre")
  end

  context "app_filter" do
    it "#index_areas" do
      visit index_areas_path
      expect(current_path).to eq index_areas_path
    end

    it "#index_tags" do
      visit index_tags_path
      expect(current_path).to eq index_tags_path
    end

    it "#index_licenses" do
      visit index_licenses_path
      expect(current_path).to eq index_licenses_path
    end
  end

  context "when logged in" do
    before do
      login_opendata_member(site, node_login)
    end

    after do
      logout_opendata_member(site, node_login)
    end

    it "shows point" do
      visit index_path
      within "article.tab-released" do
        click_on app.name
      end
      expect(page).to have_css("#executed", text: "1 #{I18n.t("opendata.labels.time")}")
      expect(page).to have_css(".count .number", text: "0")
      within "div.like" do
        click_on "いいね！"
      end
      expect(page).to have_css(".count .number", text: "1")

      app.reload
      expect(app.point).to eq 1

      within ".count .label" do
        click_on "いいね！"
      end

      expect(page).to have_css(".point-members")
    end

    it "shows new idea" do
      visit index_path
      within "article.tab-released" do
        click_on app.name
      end
      expect(page).to have_css("#executed", text: "1 #{I18n.t("opendata.labels.time")}")

      within "nav.names" do
        click_link "関連アイデア"
      end

      click_link "アイデアを投稿する"
      expect(current_path).to eq "#{node_myidea.url}new"
    end
  end

  context "when point is hide" do
    before do
      node.show_point = 'hide'
      node.save!

      # https://jira.mongodb.org/browse/MONGOID-4544
      # app.touch
      app.save!
    end

    it do
      visit index_path
      expect(page).to have_css(".opendata-tabs .tab-released h2", text: "新着順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: app.name)
      expect(page).to have_no_css(".opendata-tabs .tab-released .pages h2 .point", text: app.point.to_s, visible: false)
      expect(page).to have_css(".opendata-tabs .tab-popular h2", text: "人気順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-popular .pages h2 a", text: app.name, visible: false)
      expect(page).to have_no_css(".opendata-tabs .tab-popular .pages h2 .point", text: app.point.to_s, visible: false)
      expect(page).to have_css(".opendata-tabs .tab-attention h2", text: "注目順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-attention .pages h2 a", text: app.name, visible: false)
      expect(page).to have_no_css(".opendata-tabs .tab-attention .pages h2 .point", text: app.point.to_s, visible: false)
    end
  end

  context "when only released is enabled" do
    before do
      node.show_tabs = 'released'
      node.save!

      # https://jira.mongodb.org/browse/MONGOID-4544
      # app.touch
      app.save!
    end

    it do
      visit index_path
      expect(page).to have_no_css(".opendata-tabs .names", visible: false)

      expect(page).to have_css(".opendata-tabs .tab-released h2", text: "新着順", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: app.name)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 .point", text: app.point.to_s, visible: false)
      expect(page).to have_no_css(".opendata-tabs .tab-popular", visible: false)
      expect(page).to have_no_css(".opendata-tabs .tab-attention", text: "注目順", visible: false)
    end
  end

  context "when only released is enabled" do
    before do
      node.show_tabs = 'released'
      node.tab_titles = { 'released' => 'アプリ一覧' }
      node.save!

      # https://jira.mongodb.org/browse/MONGOID-4544
      # app.touch
      app.save!
    end

    it do
      visit index_path
      expect(page).to have_no_css(".opendata-tabs .names", visible: false)

      expect(page).to have_css(".opendata-tabs .tab-released h2", text: "アプリ一覧", visible: false)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 a", text: app.name)
      expect(page).to have_css(".opendata-tabs .tab-released .pages h2 .point", text: app.point.to_s, visible: false)
      expect(page).to have_no_css(".opendata-tabs .tab-popular", visible: false)
      expect(page).to have_no_css(".opendata-tabs .tab-attention", text: "注目順", visible: false)
    end
  end
end
