require 'spec_helper'

describe "gws_sites menu setting manual url", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:ja_url) { "https://example.jp/ja.pdf" }
  let(:en_url) { "https://example.jp/en.pdf" }

  before { login_gws_user }

  it "shows manual url fields for a target menu, hides for a non-target menu, and saves/retains values" do
    visit gws_site_path(site: site)
    click_on I18n.t("ss.links.edit")

    within "form#item-form" do
      ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
      within "#addon-gws-agents-addons-system-menu_setting" do
        # 対象メニュー(tabular)には日本語/英語のマニュアルURL欄がある
        expect(page).to have_field("item[menu_tabular_help_url]")
        expect(page).to have_field("item[menu_tabular_help_url_en]")
        # 非対象メニュー(staff_record)にはマニュアルURL欄が無い
        expect(page).to have_no_field("item[menu_staff_record_help_url]")
        expect(page).to have_no_field("item[menu_staff_record_help_url_en]")

        fill_in "item[menu_tabular_help_url]", with: ja_url
        fill_in "item[menu_tabular_help_url_en]", with: en_url
      end

      click_on I18n.t("ss.buttons.save")
    end
    wait_for_notice I18n.t('ss.notice.saved')

    site.reload
    expect(site.menu_tabular_help_url).to eq ja_url
    expect(site.menu_tabular_help_url_en).to eq en_url

    # 再編集で保存済みの値が保持されている
    visit gws_site_path(site: site)
    click_on I18n.t("ss.links.edit")
    within "form#item-form" do
      ensure_addon_opened("#addon-gws-agents-addons-system-menu_setting")
      within "#addon-gws-agents-addons-system-menu_setting" do
        expect(page).to have_field("item[menu_tabular_help_url]", with: ja_url)
        expect(page).to have_field("item[menu_tabular_help_url_en]", with: en_url)
      end
    end
  end
end
