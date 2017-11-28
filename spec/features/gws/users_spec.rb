require 'spec_helper'

describe "gws_users", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:group) { gws_group }
  let(:item) { create :ss_user, group_ids: [gws_user.group_ids.first] }
  let(:index_path) { gws_users_path site }
  let(:new_path) { "#{index_path}/new" }
  let(:show_path) { "#{index_path}/#{item.id}" }
  let(:edit_path) { "#{index_path}/#{item.id}/edit" }
  let(:delete_path) { "#{index_path}/#{item.id}/delete" }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index", js: true do
      visit index_path
      expect(current_path).to eq index_path

      #new"
      visit new_path
      first('.mod-gws-user-groups').click_on "グループを選択する"
      wait_for_cbox
      first('tbody.items a.select-item').click

      within "form#item-form" do
        name = unique_id
        fill_in "item[name]", with: name
        fill_in "item[email]", with: "#{name}@example.jp"
        fill_in "item[in_password]", with: "pass"
        click_button "保存"
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      #show
      visit show_path
      expect(current_path).to eq show_path

      #edit
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        click_button "保存"
      end
      expect(current_path).to eq show_path
      expect(page).to have_no_css("form#item-form")

      #delete
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path

      #download
      visit index_path
      click_link I18n.t('ss.links.download')

      visit "#{index_path}/download_template"

      #import
      visit index_path
      click_link I18n.t('ss.links.import')
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/user/gws_users.csv"
        click_button "インポート"
      end
      expect(current_path).to eq index_path
    end
  end
end
