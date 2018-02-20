require 'spec_helper'

describe "gws_schedule_group_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:group) { gws_user.groups.first }
  let!(:item) { create :gws_schedule_plan }
  let(:index_path) { gws_schedule_group_plans_path site, group }
  let(:new_path) { new_gws_schedule_group_plan_path site, group }
  let(:show_path) { gws_schedule_group_plan_path site, group, item }
  let(:edit_path) { edit_gws_schedule_group_plan_path site, group, item }
  let(:delete_path) { soft_delete_gws_schedule_group_plan_path site, group, item }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        click_button "保存"
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: '保存しました。')
    end

    it "#show" do
      visit show_path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: '保存しました。')
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: '保存しました。')
    end
  end
end
