require 'spec_helper'

describe "cms_translate_text_caches", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:index_path) { cms_translate_text_caches_path site.id }
  let(:new_path) { new_cms_translate_text_cach_path site.id }
  let(:show_path) { cms_translate_text_cach_path site.id, item.id }
  let(:edit_path) { edit_cms_translate_text_cach_path site.id, item.id }
  let(:delete_path) { delete_cms_translate_text_cach_path site.id, item.id }

  let!(:lang_ja) { create :translate_lang_ja }
  let!(:lang_en) { create :translate_lang_en }
  let!(:lang_ko) { create :translate_lang_ko }
  let!(:lang_zh_CN) { create :translate_lang_zh_cn }
  let!(:lang_zh_TW) { create :translate_lang_zh_tw }

  let(:text1) { "first" }
  let(:text2) { "second" }
  let(:text3) { "third" }
  let(:html) { "<div><p>#{text1}</p><p>#{text2}</p></div>" }
  let(:source) { "ja" }
  let(:target) { "en" }
  let(:item) { Translate::TextCache.site(site).first }

  context "basic crud" do
    before do
      site.translate_state = "enabled"
      site.translate_api = "mock"
      site.translate_source = lang_ja
      site.translate_target_ids = [lang_en, lang_ko, lang_zh_CN, lang_zh_TW].map(&:id)
      site.update!

      lang_ja = Translate::Lang.site(site).find_by(code: source)
      lang_en = Translate::Lang.site(site).find_by(code: target)
      item = Translate::Convertor.new(site, lang_ja, lang_en)
      item.convert(html)

      login_cms_user
    end

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_css(".translate-text-chaches tr td", text: text1)
      expect(page).to have_css(".translate-text-chaches tr td", text: text1)
      expect(page).to have_css(".translate-text-chaches tr td", text: text2)
      expect(page).to have_css(".translate-text-chaches tr td", text: text2)
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[original_text]", with: text1
        fill_in "item[text]", with: "tr-#{text1}"
        fill_in "item[source]", with: source
        fill_in "item[target]", with: target
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#errorExplanation')

      within "form#item-form" do
        fill_in "item[original_text]", with: text3
        fill_in "item[text]", with: "tr-#{text3}"
        fill_in "item[source]", with: source
        fill_in "item[target]", with: target
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic dd", text: item.label(:api))
      expect(page).to have_css("#addon-basic dd", text: item.original_text)
      expect(page).to have_css("#addon-basic dd", text: item.text)
      expect(page).to have_css("#addon-basic dd", text: item.source)
      expect(page).to have_css("#addon-basic dd", text: item.target)
    end

    it "#edit" do
      visit edit_path

      within "form#item-form" do
        fill_in "item[original_text]", with: text1
        fill_in "item[text]", with: "tr-#{text1}"
        fill_in "item[source]", with: source
        fill_in "item[target]", with: target
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#errorExplanation')

      within "form#item-form" do
        fill_in "item[original_text]", with: item.original_text
        fill_in "item[text]", with: "tr-#{item.text}"
        fill_in "item[source]", with: item.source
        fill_in "item[target]", with: item.target
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end
  end
end
