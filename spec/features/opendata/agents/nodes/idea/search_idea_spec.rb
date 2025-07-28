require 'spec_helper'

describe "opendata_search_ideas", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node_idea) { create :opendata_node_idea, cur_site: site, layout_id: layout.id }
  let!(:node_idea_search) { create(:opendata_node_search_idea, cur_site: site, cur_node: node_idea, layout_id: layout.id) }

  let(:index_path) { "#{node_idea_search.url}index.html" }
  let(:rss_path) { "#{node_idea_search.url}rss.xml" }
  let!(:node_category_folder) { create(:cms_node_node, cur_site: site, layout_id: layout.id) }
  let!(:node_category) do
    create(
      :opendata_node_category, cur_site: site, cur_node: node_category_folder, layout_id: layout.id,
      basename: "kurashi",
      name: 'カテゴリー０１')
  end
  let!(:node_area) { create :opendata_node_area, cur_site: site, layout_id: layout.id, name: '地域Ａ' }

  before do
    params = {
      cur_site: site,
      cur_node: node_idea,
      layout_id: layout.id,
      category_ids: [ node_category.id ],
      area_ids: [ node_area.id ]
    }

    10.times.each do |index|
      params[:issue] = "issue#{index}"
      params[:text] = "text#{index}"
      params[:data] = "data#{index}"
      params[:note] = "note#{index}"
      params[:tags] = [ "tag#{index}" ]
      create :opendata_idea, params
    end
  end

  context "search_idea" do
    it "#index" do
      visit index_path
      expect(current_path).to eq index_path

      expect(page).to have_css('.opendata-search-ideas-form')
      expect(page).to have_css('.opendata-search-ideas article', count: 10)
      within first('.opendata-search-ideas article') do
        expect(page).to have_css('time')
        expect(page).to have_css('h2 a')
        expect(page).to have_css('h2 .point')
        expect(page).to have_css('.categories .category')
        expect(page).to have_css('.categories .area')
        expect(page).to have_css('.categories .tag')
      end
    end

    it "#index released" do
      visit "#{index_path}?&sort=released"
      expect(current_path).to eq index_path

      expect(page).to have_css('.opendata-search-ideas-form')
      expect(page).to have_css('.opendata-search-ideas article', count: 10)
      within first('.opendata-search-ideas article') do
        expect(page).to have_css('time')
        expect(page).to have_css('h2 a')
        expect(page).to have_css('h2 .point')
        expect(page).to have_css('.categories .category')
        expect(page).to have_css('.categories .area')
        expect(page).to have_css('.categories .tag')
      end
    end

    it "#index popular" do
      visit "#{index_path}?&sort=popular"
      expect(current_path).to eq index_path

      expect(page).to have_css('.opendata-search-ideas-form')
      expect(page).to have_css('.opendata-search-ideas article', count: 10)
      within first('.opendata-search-ideas article') do
        expect(page).to have_css('time')
        expect(page).to have_css('h2 a')
        expect(page).to have_css('h2 .point')
        expect(page).to have_css('.categories .category')
        expect(page).to have_css('.categories .area')
        expect(page).to have_css('.categories .tag')
      end
    end

    it "#index attention" do
      visit "#{index_path}?&sort=attention"
      expect(current_path).to eq index_path

      expect(page).to have_css('.opendata-search-ideas-form')
      expect(page).to have_css('.opendata-search-ideas article', count: 10)
      within first('.opendata-search-ideas article') do
        expect(page).to have_css('time')
        expect(page).to have_css('h2 a')
        expect(page).to have_css('h2 .point')
        expect(page).to have_css('.categories .category')
        expect(page).to have_css('.categories .area')
        expect(page).to have_css('.categories .tag')
      end
    end

    it "#keyword_input" do
      visit index_path
      fill_in "s_keyword", with: "アイデア"
      click_button I18n.t('ss.buttons.search')
      within first('.opendata-search-ideas article') do
        expect(page).to have_css('h2', text: 'アイデアは見つかりませんでした。')
      end
    end

    it "#keyword_input" do
      visit index_path
      fill_in "s_keyword", with: "text3"
      click_button I18n.t('ss.buttons.search')

      page_idea = Opendata::Idea.find_by(text: 'text3')
      within first('.opendata-search-ideas article') do
        expect(page).to have_css('time', text: I18n.l(page_idea.date.to_date, format: :long))
        expect(page).to have_css('h2 a', text: page_idea.name)
        expect(page).to have_css('h2 .point', text: page_idea.point.to_s)
        expect(page).to have_css('.categories .category', text: page_idea.categories.first.name)
        expect(page).to have_css('.categories .area', text: page_idea.areas.first.name)
        expect(page).to have_css('.categories .tag', text: page_idea.tags.first)
      end
    end

    it "multiple keywords_input" do
      visit index_path
      fill_in "s_keyword", with: "text3 text7"
      select "すべてのキーワードを含む"
      click_button I18n.t('ss.buttons.search')

      expect(page).to have_css('.opendata-search-ideas article', count: 1)
      within first('.opendata-search-ideas article') do
        expect(page).to have_css('h2', text: 'アイデアは見つかりませんでした。')
      end

      select "いずれかのキーワードを含む"
      click_button I18n.t('ss.buttons.search')

      expect(page).to have_css('.opendata-search-ideas article', count: 2)
    end

    it "#category_select" do
      visit index_path
      select node_category.name
      click_button I18n.t('ss.buttons.search')

      page_idea = Opendata::Idea.site(site).search(site: site, category_id: node_category.id).order_by(released: -1).first
      within first('.opendata-search-ideas article') do
        expect(page).to have_css('time', text: I18n.l(page_idea.date.to_date, format: :long))
        expect(page).to have_css('h2 a', text: page_idea.name)
        expect(page).to have_css('h2 .point', text: page_idea.point.to_s)
        expect(page).to have_css('.categories .category', text: page_idea.categories.first.name)
        expect(page).to have_css('.categories .area', text: page_idea.areas.first.name)
        expect(page).to have_css('.categories .tag', text: page_idea.tags.first)
      end
    end

    it "#area_select" do
      visit index_path
      select node_area.name
      click_button I18n.t('ss.buttons.search')

      page_idea = Opendata::Idea.site(site).search(site: site, area_id: node_area.id).order_by(released: -1).first
      within first('.opendata-search-ideas article') do
        expect(page).to have_css('time', text: I18n.l(page_idea.date.to_date, format: :long))
        expect(page).to have_css('h2 a', text: page_idea.name)
        expect(page).to have_css('h2 .point', text: page_idea.point.to_s)
        expect(page).to have_css('.categories .category', text: page_idea.categories.first.name)
        expect(page).to have_css('.categories .area', text: page_idea.areas.first.name)
        expect(page).to have_css('.categories .tag', text: page_idea.tags.first)
      end
    end

    it "#tag_input" do
      visit index_path
      select "tag5"
      click_button I18n.t('ss.buttons.search')

      page_idea = Opendata::Idea.find_by(tags: 'tag5')
      within first('.opendata-search-ideas article') do
        expect(page).to have_css('time', text: I18n.l(page_idea.date.to_date, format: :long))
        expect(page).to have_css('h2 a', text: page_idea.name)
        expect(page).to have_css('h2 .point', text: page_idea.point.to_s)
        expect(page).to have_css('.categories .category', text: page_idea.categories.first.name)
        expect(page).to have_css('.categories .area', text: page_idea.areas.first.name)
        expect(page).to have_css('.categories .tag', text: page_idea.tags.first)
      end
    end

    it "keyword and tag input" do
      visit index_path
      fill_in "s_keyword", with: "text3"
      select "tag5"
      select "すべてのキーワードを含む"
      click_button I18n.t('ss.buttons.search')

      expect(page).to have_css('.opendata-search-ideas article', count: 1)
      within first('.opendata-search-ideas article') do
        expect(page).to have_css('h2', text: 'アイデアは見つかりませんでした。')
      end

      select "いずれかのキーワードを含む"
      click_button I18n.t('ss.buttons.search')

      expect(page).to have_css('.opendata-search-ideas article', count: 1)
      within first('.opendata-search-ideas article') do
        expect(page).to have_css('h2', text: 'アイデアは見つかりませんでした。')
      end

      select "すべてをOR条件で検索する"
      click_button I18n.t('ss.buttons.search')
      expect(page).to have_css('.opendata-search-ideas article', count: 2)
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
        expect(items).to have(10).items
      end
    end
  end

  context "when point is hide" do
    before do
      node_idea.show_point = 'hide'
      node_idea.save!

      Opendata::Idea.all.each do |page_idea|
        # https://jira.mongodb.org/browse/MONGOID-4544
        # page_idea.touch
        page_idea.save!
      end
    end

    it "#index" do
      visit index_path
      expect(current_path).to eq index_path

      expect(page).to have_css('.opendata-search-ideas-form')
      expect(page).to have_css('.opendata-search-ideas article', count: 10)
      within first('.opendata-search-ideas article') do
        expect(page).to have_css('time')
        expect(page).to have_css('h2 a')
        expect(page).to have_no_css('h2 .point')
        expect(page).to have_css('.categories .category')
        expect(page).to have_css('.categories .area')
        expect(page).to have_css('.categories .tag')
      end
    end
  end
end
