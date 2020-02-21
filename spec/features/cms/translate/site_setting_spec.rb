require 'spec_helper'

describe "cms_translate_site_setting", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:show_path) { cms_translate_site_setting_path site.id }
  let(:edit_path) { edit_cms_translate_site_setting_path site.id }

  let!(:lang_ja) { create :translate_lang_ja }
  let!(:lang_en) { create :translate_lang_en }
  let!(:lang_ko) { create :translate_lang_ko }
  let!(:lang_zh_CN) { create :translate_lang_zh_cn }
  let!(:lang_zh_TW) { create :translate_lang_zh_tw }

  let(:google_api) { SS.config.translate.api_options["google_translation"] }
  let(:microsoft_api) { SS.config.translate.api_options["microsoft_translator_text"] }

  context "basic crud" do
    before { login_cms_user }

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic dt", text: site.t(:translate_source_id))
      expect(page).to have_css("#addon-basic dt", text: site.t(:translate_target_ids))
    end

    it "#edit" do
      visit edit_path
      expect(current_path).not_to eq sns_login_path

      within "form#item-form" do
        select I18n.t('ss.options.state.enabled'), from: "item[translate_state]"
        first('[name="item[translate_source_id]"] + .ajax-box').click
      end
      wait_for_cbox do
        click_on lang_ja.name
      end
      within "form#item-form" do
        first('[name="item[translate_target_ids][]"] + .ajax-box').click
      end
      wait_for_cbox do
        click_on lang_en.name
      end
      within "form#item-form" do
        select google_api, from: "item[translate_api]"
        click_button I18n.t('ss.buttons.save')
      end

      expect(page).to have_css("#addon-basic dd", text: lang_ja.label)
      expect(page).to have_css("#addon-basic dd", text: lang_en.label)
    end
  end
end
