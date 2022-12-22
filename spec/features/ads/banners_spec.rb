require 'spec_helper'

describe "ads_banners", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create_once :ads_node_banner, name: "ads" }
  let(:index_path) { ads_banners_path site.id, node }
  let!(:file) do
    tmp_ss_file(
      Cms::TempFile, user: cms_user, site: site, node: node, contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
    )
  end
  let(:name) { "sample" }
  let(:name2) { "modify" }

  before { login_cms_user }

  context "basic crud" do
    it do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[link_url]", with: "http://example.jp"
        first(".btn-file-upload").click
      end
      wait_for_cbox do
        expect(page).to have_css(".file-view", text: file.name)
        click_on file.name
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit index_path
      click_on name
      expect(page).to have_css("#addon-basic", text: name)
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit index_path
      click_on name2
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
    end
  end

  context "when additional_attr is nil" do
    let!(:item) { create :ads_banner, filename: "ads/item", additional_attr: nil }

    it do
      visit ads_banner_path(site.id, node, item)
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit index_path
      click_on name2
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
    end
  end

  context "when workflow settings are enabled" do
    let!(:item) { create :ads_banner, filename: "ads/item" }

    it do
      site.update(
        approve_remind_state: 'enabled',
        approve_remind_later: '1.day'
      )

      visit ads_banner_path(site.id, node, item)
      expect(page).to have_content(item.name)
    end
  end
end
