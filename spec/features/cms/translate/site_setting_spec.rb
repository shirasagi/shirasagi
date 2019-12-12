require 'spec_helper'

describe "cms_translate_site_setting", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:show_path) { cms_translate_site_setting_path site.id }
  let(:edit_path) { edit_cms_translate_site_setting_path site.id }
  let(:translate_source) { "ja" }
  let(:translate_targets) { %w(en ko zh-CN zh-TW) }

  context "basic crud" do
    before { login_cms_user }

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_css("#addon-basic dt", text: site.t(:translate_source))
      expect(page).to have_css("#addon-basic dt", text: site.t(:translate_targets))
    end

    it "#edit" do
      visit edit_path
      expect(current_path).not_to eq sns_login_path

      within "form#item-form" do
        fill_in "item[translate_source]", with: translate_source
        fill_in "item[translate_targets]", with: translate_targets.join("\n")
        click_button I18n.t('ss.buttons.save')
      end

      expect(page).to have_css("#addon-basic dd", text: translate_source)
      translate_targets.each do |target|
        expect(page).to have_css("#addon-basic dd", text: target)
      end
    end
  end
end
