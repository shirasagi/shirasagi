require 'spec_helper'

describe "cms_translate_langs", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:index_path) { cms_translate_langs_path site.id }
  let(:new_path) { new_cms_translate_lang_path site.id }
  let(:show_path) { cms_translate_lang_path site.id, item.id }
  let(:edit_path) { edit_cms_translate_lang_path site.id, item.id }
  let(:delete_path) { delete_cms_translate_lang_path site.id, item.id }
  let(:import_path) { import_cms_translate_langs_path site.id }

  let(:item) do
    create :translate_lang_ja, code: code, name: name,
      google_translation_code: google_translation_code,
      microsoft_translator_text_code: microsoft_translator_text_code,
      mock_code: mock_code,
      accept_languages: accept_languages
  end
  let(:code) { "ja" }
  let(:name) { "japanese" }
  let(:google_translation_code) { "ja-google" }
  let(:microsoft_translator_text_code) { "ja-ms" }
  let(:mock_code) { "ja-mock" }
  let(:accept_languages) { ["ja-1", "ja-2", "ja-3"]}
  let(:item_csv) do
    [
      item.code,
      item.name,
      item.google_translation_code,
      item.microsoft_translator_text_code,
      item.mock_code,
      item.accept_languages.join("\n")
    ]
  end

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      item
      visit index_path
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_css(".list-items", text: item.label)
    end

    it "#new" do
      item
      visit new_path
      within "form#item-form" do
        fill_in "item[code]", with: item.code
        fill_in "item[name]", with: item.name
        fill_in "item[google_translation_code]", with: item.google_translation_code
        fill_in "item[microsoft_translator_text_code]", with: item.microsoft_translator_text_code
        fill_in "item[mock_code]", with: item.mock_code
        fill_in "item[accept_languages]", with: item.accept_languages.join("\n")
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#errorExplanation')

      within "form#item-form" do
        fill_in "item[code]", with: "en"
        fill_in "item[name]", with: "英語"
        fill_in "item[google_translation_code]", with: "en"
        fill_in "item[microsoft_translator_text_code]", with: "en"
        fill_in "item[mock_code]", with: "en"
        fill_in "item[accept_languages]", with: "en"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic dd", text: item.code)
      expect(page).to have_css("#addon-basic dd", text: item.name)
      expect(page).to have_css("#addon-basic dd", text: item.google_translation_code)
      expect(page).to have_css("#addon-basic dd", text: item.microsoft_translator_text_code)
      expect(page).to have_css("#addon-basic dd", text: item.mock_code)
      expect(page).to have_css("#addon-basic dd", text: item.accept_languages[0])
      expect(page).to have_css("#addon-basic dd", text: item.accept_languages[1])
      expect(page).to have_css("#addon-basic dd", text: item.accept_languages[2])
    end

    it "#edit" do
      visit edit_path

      within "form#item-form" do
        fill_in "item[name]", with: "japanese"
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

    it "#download" do
      item
      visit index_path
      click_on I18n.t("ss.buttons.download")

      expect(page.response_headers["Transfer-Encoding"]).to eq "chunked"
      csv = ::SS::ChunkReader.new(page.html).to_a.join
      csv = csv.encode("UTF-8", "SJIS")
      csv = ::CSV.parse(csv)

      expect(csv.length).to eq 2
      expect(csv[0]).to eq item.class.csv_headers
      expect(csv[1]).to eq item_csv
    end

    it "#import" do
      item
      visit import_path

      click_button I18n.t('ss.buttons.import')
      expect(page).to have_css("#errorExplanation")

      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/db/seeds/demo/translate/lang.csv"
        click_button I18n.t('ss.buttons.import')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      count = Translate::Lang.count
      lang_ja = Translate::Lang.site(site).where(code: "ja").first
      lang_en = Translate::Lang.site(site).where(code: "en").first

      expect(count).to eq 112

      expect(lang_ja.code).to eq "ja"
      expect(lang_ja.name).to eq "日本語"
      expect(lang_ja.google_translation_code).to eq "ja"
      expect(lang_ja.microsoft_translator_text_code).to eq "ja"
      expect(lang_ja.mock_code).to eq "ja"
      expect(lang_ja.accept_languages).to eq %w(ja)

      expect(lang_en.code).to eq "en"
      expect(lang_en.name).to eq "英語"
      expect(lang_en.google_translation_code).to eq "en"
      expect(lang_en.microsoft_translator_text_code).to eq "en"
      expect(lang_en.mock_code).to eq "en"
      expect(lang_en.accept_languages).to eq %w(en)
    end
  end
end
