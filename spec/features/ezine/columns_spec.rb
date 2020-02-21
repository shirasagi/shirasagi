require 'spec_helper'

describe "ezine_columns", type: :feature do
  subject(:site) { cms_site }
  subject(:node) { create_once :ezine_node_page }
  subject(:item) { Ezine::Column.last }
  subject(:index_path) { ezine_columns_path site.id, node }
  subject(:new_path) { new_ezine_column_path site.id, node }
  subject(:show_path) { ezine_column_path site.id, node, item }
  subject(:edit_path) { edit_ezine_column_path site.id, node, item }
  subject(:delete_path) { delete_ezine_column_path site.id, node, item }

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
        click_button I18n.t('ss.buttons.save')
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end
  end
end
