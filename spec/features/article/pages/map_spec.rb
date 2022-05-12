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
    end
  end
end
