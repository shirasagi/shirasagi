require 'spec_helper'

describe "gws_bookmark_items", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:index_path) { gws_bookmark_main_path site }

  before { login_gws_user }

  shared_examples "bookmark main" do
    it do
      visit bookmark_path
      within ".gws-bookmark" do
        expect(page).to have_css("i.inactive")
        expect(page).to have_no_css(".bookmark-notice")
      end
      first(".gws-bookmark").click
      within ".gws-bookmark" do
        expect(page).to have_css("i.active")
        expect(page).to have_selector(".bookmark-notice", visible: true)
      end

      visit index_path
      within ".index .list-items" do
        expect(page).to have_selector(".list-item", count: 1)
        expect(page).to have_css(".list-item .bookmark_model", text: bookmark_model)
      end

      visit bookmark_path
      within ".gws-bookmark" do
        expect(page).to have_css("i.active")
        expect(page).to have_selector(".bookmark-notice", visible: false)
      end
      first(".gws-bookmark").click
      within ".gws-bookmark" do
        expect(page).to have_css("i.active")
        expect(page).to have_selector(".bookmark-notice", visible: true)
        click_on I18n.t("ss.buttons.delete")
      end
      within ".gws-bookmark" do
        expect(page).to have_css("i.inactive")
        expect(page).to have_no_css(".bookmark-notice")
      end

      visit index_path
      within ".index .list-items" do
        expect(page).to have_selector(".list-item", count: 0)
      end
    end
  end

  context "portal" do
    let(:bookmark_path) { gws_portal_path site }
    let(:bookmark_model) { I18n.t("modules.gws/portal") }

    it_behaves_like "bookmark main"
  end

  context "notice" do
    let(:bookmark_path) { gws_notice_main_path site }
    let(:bookmark_model) { I18n.t("modules.gws/bookmark") }

    it_behaves_like "bookmark main"
  end

  context "presence" do
    let(:bookmark_path) { gws_presence_main_path site }
    let(:bookmark_model) { I18n.t("modules.gws/presence") }

    it_behaves_like "bookmark main"
  end

  context "workflow" do
    let(:bookmark_path) { gws_workflow_files_main_path site }
    let(:bookmark_model) { I18n.t("modules.gws/workflow") }

    it_behaves_like "bookmark main"
  end

  context "circular" do
    let(:bookmark_path) { gws_circular_main_path site }
    let(:bookmark_model) { I18n.t("modules.gws/circular") }

    it_behaves_like "bookmark main"
  end

  context "survey" do
    let(:bookmark_path) { gws_survey_main_path site }
    let(:bookmark_model) { I18n.t("modules.gws/survey") }

    it_behaves_like "bookmark main"
  end

  context "faq" do
    let(:bookmark_path) { gws_faq_main_path site }
    let(:bookmark_model) { I18n.t("modules.gws/faq") }

    it_behaves_like "bookmark main"
  end

  #context "elasticsearch" do
  #  let(:bookmark_path) { gws_elasticsearch_search_main_path site }
  #  let(:bookmark_model) { I18n.t("modules.gws/elasticsearch") }
  #
  #  it_behaves_like "bookmark main"
  #end
end
