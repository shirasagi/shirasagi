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

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end

    it "#new", js: true do
      visit new_path
      first('.mod-gws-user').click_on "グループを選択する"
      group = gws_user.groups.first
      # first('a', text: group.trailing_name).click
      parent_group = Gws::Group.find_by(name: group.name.split('/')[0..-2].join('/'))
      first('a', text: parent_group.trailing_name).click

      within "form#item-form" do
        name = unique_id
        fill_in "item[name]", with: name
        fill_in "item[email]", with: "#{name}@example.jp"
        fill_in "item[in_password]", with: "pass"
        click_button "保存"
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).to eq show_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq show_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end

    it "#download" do
      visit index_path
      click_link I18n.t('ss.links.download')
      expect(status_code).to eq 200

      visit "#{index_path}/download_template"
      expect(status_code).to eq 200
    end

    it "#import" do
      visit index_path
      click_link I18n.t('ss.links.import')
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/user/gws_users.csv"
        click_button "インポート"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end
  end
end
