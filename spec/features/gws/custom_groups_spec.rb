require 'spec_helper'

describe "gws_custom_groups", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_custom_groups_path site }
  let(:item) { create :gws_custom_group }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      item
      visit path
      expect(page).to have_content(item.name)
    end

    it "#new" do
      visit "#{path}/new"
      first('#addon-gws-agents-addons-member').click_on "ユーザーを選択する"
      wait_for_cbox
      click_on gws_user.long_name

      within "form#item-form" do
        fill_in "item[name]", with: "name"
        click_button "保存"
      end
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit "#{path}/#{item.id}"
      expect(page).to have_content(item.name)
    end

    it "#edit" do
      visit "#{path}/#{item.id}/edit"
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        click_button "保存"
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#delete" do
      visit "#{path}/#{item.id}/delete"
      within "form" do
        click_button "削除"
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end
  end
end
