require 'spec_helper'

describe "theme/public_filter", type: :feature, dbscope: :example, js: true do
  shared_examples "theme" do
    let!(:site) { cms_site }
    let!(:layout) { create_cms_layout part }
    let!(:node) { create :article_node_page, cur_site: site, cur_user: cms_user, layout_id: layout.id }

    before do
      login_cms_user
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      fill_in "item[name]", with: "sample"
      click_on I18n.t("ss.links.input")
      fill_in "item[basename]", with: "sample"
      click_on I18n.t("ss.buttons.publish_save")
      click_on I18n.t("ss.buttons.ignore_alert")
    end

    it "index" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        white_button = find('.white')
        blue_button = find('.blue')
        black_button = find('.black')
        expect(white_button[:'aria-pressed']).to eq('true')
        expect(blue_button[:'aria-pressed']).to eq('false')
        expect(black_button[:'aria-pressed']).to eq('false')
      end
    end

    it "click blue button" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        white_button = find('.accessibility__theme button.white')
        blue_button = find('.blue')
        black_button = find('.black')
        blue_button.click
        expect(white_button[:'aria-pressed']).to eq('false')
        expect(blue_button[:'aria-pressed']).to eq('true')
        expect(black_button[:'aria-pressed']).to eq('false')
      end
    end

    it "click black button" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        white_button = find('.accessibility__theme button.white')
        blue_button = find('.blue')
        black_button = find('.black')
        black_button.click
        expect(white_button[:'aria-pressed']).to eq('false')
        expect(blue_button[:'aria-pressed']).to eq('false')
        expect(black_button[:'aria-pressed']).to eq('true')
      end
    end

    it "click white button" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        white_button = find('.accessibility__theme button.white')
        blue_button = find('.blue')
        black_button = find('.black')
        white_button.click
        expect(white_button[:'aria-pressed']).to eq('false')
        expect(blue_button[:'aria-pressed']).to eq('false')
        expect(black_button[:'aria-pressed']).to eq('true')
      end
    end
  end

  context "with latest accessibility html" do
    let!(:part) { create :accessibility_tool, cur_site: site }

    it_behaves_like "theme"
  end

  context "with old accessibility html 1" do
    let!(:part) { create :accessibility_tool_compat1, cur_site: site }

    it_behaves_like "theme"
  end
end
