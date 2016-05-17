require 'spec_helper'

describe "gws_schedule_user_plans", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:item) { create :gws_schedule_plan }
  let(:index_path) { gws_schedule_user_plans_path site, gws_user }
  let(:new_path) { new_gws_schedule_user_plan_path site, gws_user }
  let(:show_path) { gws_schedule_user_plan_path site, gws_user, item }
  let(:edit_path) { edit_gws_schedule_user_plan_path site, gws_user, item }
  let(:delete_path) { delete_gws_schedule_user_plan_path site, gws_user, item }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#events" do
      item
      today = Time.zone.today
      sdate = today - today.day + 1.day
      edate = sdate + 1.month
      visit "#{index_path}/events.json?s[start]=#{sdate}&s[end]=#{edate}"
      expect(page.body).to have_content(item.name)
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        click_button "保存"
      end
      expect(status_code.to_s).to match /200|302/
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
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
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).not_to have_css("form#item-form")
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
