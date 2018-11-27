require 'spec_helper'

describe "inquiry_columns" do
  subject(:site) { cms_site }
  subject(:node) { create_once :article_node_page, name: "article" }
  subject(:item) { Inquiry::Column.last }
  subject(:index_path) { inquiry_columns_path site.id, node }
  subject(:new_path) { new_inquiry_column_path site.id, node }
  subject(:show_path) { inquiry_column_path site.id, node, item }
  subject(:edit_path) { edit_inquiry_column_path site.id, node, item }
  subject(:delete_path) { delete_inquiry_column_path site.id, node, item }

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
        fill_in "item[html]", with: "<p>sample</p>"
        select I18n.t('ss.options.state.public'), from: 'item_state'
        fill_in "item[order]", with: 0
        select I18n.t('inquiry.options.input_type.text_field'), from: 'item_input_type'
        fill_in "item[select_options]", with: "sample"
        select I18n.t('inquiry.options.required.required'), from: 'item_required'
        fill_in "item[additional_attr]", with: "sample"
        select I18n.t('inquiry.options.input_confirm.disabled'), from: 'item_input_confirm'
        select I18n.t('ss.options.state.disabled'), from: 'item_question'
        fill_in "item[max_upload_file_size]", with: 0
        fill_in "item[transfers][][keyword]", with: "sample"
        fill_in "item[transfers][][email]", with: "sample@example.jp"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_css('td', text: 'sample@example.jp')
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end
  end
end
