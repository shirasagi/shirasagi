require 'spec_helper'

describe "ezine_columns", type: :feature do
  let!(:site) { cms_site }
  let!(:node) { create :ezine_node_page, cur_site: site }

  context "basic crud" do
    before { login_cms_user }

    it do
      visit ezine_columns_path(site.id, node)
      expect(current_path).not_to eq sns_login_path

      visit new_ezine_column_path(site.id, node)
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_ezine_column_path(site.id, node)
      expect(page).to have_no_css("form#item-form")

      item = Ezine::Column.last
      visit ezine_column_path(site.id, node, item)
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path

      visit edit_ezine_column_path(site.id, node, item)
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")

      visit delete_ezine_column_path(site.id, node, item)
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
      expect(current_path).to eq ezine_columns_path(site.id, node)
    end
  end
end
