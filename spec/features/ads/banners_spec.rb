require 'spec_helper'

describe "ads_banners", type: :feature, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :ads_node_banner, name: "ads" }
  let(:item) { Ads::Banner.last }
  let(:index_path) { ads_banners_path site.id, node }
  let(:new_path) { new_ads_banner_path site.id, node }
  let(:show_path) { ads_banner_path site.id, node, item }
  let(:edit_path) { edit_ads_banner_path site.id, node, item }
  let(:delete_path) { delete_ads_banner_path site.id, node, item }
  let!(:file) do
    tmp_ss_file(
      Cms::TempFile, user: cms_user, site: site, node: node, contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
    )
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[link_url]", with: "http://example.jp"
        first(".btn-file-upload").click
      end
      wait_for_cbox do
        # click_on file.name
        expect(page).to have_css(".file-view", text: file.name)
        first("a[data-id='#{file.id}']").click
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
    end
  end
end
