require 'spec_helper'

describe "gws_schedule_list_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:item) { create :gws_schedule_plan }
  let(:index_path) { gws_schedule_list_plans_path site }
  let(:new_path) { new_gws_schedule_list_plan_path site }
  let(:show_path) { gws_schedule_list_plan_path site, item }
  let(:edit_path) { edit_gws_schedule_list_plan_path site, item }
  let(:delete_path) { soft_delete_gws_schedule_list_plan_path site, item }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
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
      expect(current_path).not_to eq delete_path
    end
  end
end
