require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node) { create :article_node_page, cur_site: site, layout: layout }
  let(:name) { "name-#{unique_id}" }
  let(:loc) { "138.346223,36.152318" }
  let(:marker_name) { "marker-#{unique_id}" }
  let(:marker_text) { "text-#{unique_id}" }

  before do
    site.map_api = "openlayers"
    site.map_api_layer = "国土地理院地図"
    site.map_api_mypage = "active"
    site.save!

    login_cms_user
  end

  context "without lgwan enabled" do
    it do
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")

      ensure_addon_opened("#addon-map-agents-addons-page")
      within "form#item-form" do
        fill_in "item[name]", with: name

        within "#addon-map-agents-addons-page" do
          expect(page).to have_css(".map-canvas .ol-overlaycontainer")

          within ".marker-setting [data-id='0']" do
            fill_in "item[map_points][][loc_]", with: loc
            fill_in "item[map_points][][name]", with: marker_name
            fill_in "item[map_points][][text]", with: marker_text

            click_on I18n.t("map.buttons.set_marker")
          end
        end

        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      expect(Article::Page.site(site).node(node).count).to eq 1
      article_page = Article::Page.site(site).node(node).first

      visit article_page.full_url
      expect(page).to have_css(".map-page .ol-overlaycontainer")
    end
  end

  context "with lgwan enabled" do
    before do
      # enable lgwan
      @save_lgwan_disable = SS.config.lgwan.disable
      SS.config.replace_value_at(:lgwan, :disable, false)
    end

    after do
      SS.config.replace_value_at(:lgwan, :disable, @save_lgwan_disable)
    end

    it do
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")

      ensure_addon_opened("#addon-map-agents-addons-page")
      within "form#item-form" do
        fill_in "item[name]", with: name

        within "#addon-map-agents-addons-page" do
          expect(page).to have_css(".map-canvas .ol-overlaycontainer")

          within ".marker-setting [data-id='0']" do
            fill_in "item[map_points][][loc_]", with: loc
            fill_in "item[map_points][][name]", with: marker_name
            fill_in "item[map_points][][text]", with: marker_text

            click_on I18n.t("map.buttons.set_marker")
          end
        end

        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice(I18n.t("ss.notice.saved"))

      expect(Article::Page.site(site).node(node).count).to eq 1
      article_page = Article::Page.site(site).node(node).first

      visit article_page.full_url
      expect(page).to have_css(".map-page .ol-overlaycontainer")
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:item) { create(:article_page, cur_node: node) }
  let(:index_path) { article_pages_path site.id, node }
  let(:new_path) { new_article_page_path site.id, node }
  let(:show_path) { article_page_path site.id, node, item }
  let(:edit_path) { edit_article_page_path site.id, node, item }

  context "map addon" do
    before { login_cms_user }

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_on I18n.t("ss.links.input")
        fill_in "item[basename]", with: "sample"
        click_on I18n.t("ss.buttons.draft_save")
      end
      click_on I18n.t("ss.buttons.ignore_alert")
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "map_points" do
      visit edit_path
      find("#addon-map-agents-addons-page").click
      within "form#item-form" do
        fill_in "item[map_points][][number]", with: 1
        fill_in "item[map_points][][loc_]", with: "32.0, 138.0"
        click_on I18n.t("map.buttons.set_marker")
        select I18n.t("map.show"), from: "item_map_link"
        fill_in "item[map_goal]", with: 1
        fill_in "item[map_route]", with: "1"
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_content("[32.0, 138.0]")
      expect(page).to have_content(I18n.t("map.show"))
      expect(page).to have_content("1")
    end

    it "map_points number less than 1" do
      visit edit_path
      find("#addon-map-agents-addons-page").click
      within "form#item-form" do
        fill_in "item[map_points][][number]", with: 0
        fill_in "item[map_points][][loc_]", with: "32.0, 138.0"
        click_on I18n.t("map.buttons.set_marker")
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).not_to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "map_points number max" do
      visit edit_path
      find("#addon-map-agents-addons-page").click
      within "form#item-form" do
        fill_in "item[map_points][][number]", with: 99
        fill_in "item[map_points][][loc_]", with: "32.0, 138.0"
        click_on I18n.t("map.buttons.set_marker")
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "map_points number bigger than 99" do
      visit edit_path
      find("#addon-map-agents-addons-page").click
      within "form#item-form" do
        fill_in "item[map_points][][number]", with: 100
        fill_in "item[map_points][][loc_]", with: "32.0, 138.0"
        click_on I18n.t("map.buttons.set_marker")
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).not_to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "map_goal is not in the map_points number" do
      visit edit_path
      find("#addon-map-agents-addons-page").click
      within "form#item-form" do
        fill_in "item[map_points][][number]", with: 1
        fill_in "item[map_points][][loc_]", with: "32.0, 138.0"
        fill_in "item[map_goal]", with: 2
        click_on I18n.t("map.buttons.set_marker")
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).to have_css('#errorExplanation')
    end

    it "map_route is not in the map_points number" do
      visit edit_path
      find("#addon-map-agents-addons-page").click
      within "form#item-form" do
        fill_in "item[map_points][][number]", with: 1
        fill_in "item[map_points][][loc_]", with: "32.0, 138.0"
        fill_in "item[map_route]", with: "1,2"
        click_on I18n.t("map.buttons.set_marker")
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).to have_css('#errorExplanation')
    end
  end
end
