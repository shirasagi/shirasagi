require 'spec_helper'

describe "gws_schedule_holidays", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_schedule_holidays_path site }
  let(:item) { create :gws_schedule_holiday }

  it "without login" do
    visit path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit path
    expect(status_code).to eq 403
  end

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      item
      visit path
      expect(status_code).to eq 200
      expect(page).to have_content(item.name)
    end

    it "#new" do
      visit "#{path}/new"
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        fill_in "item[start_on]", with: "2016/01/01"
        fill_in "item[end_on]", with: "2016/01/02"
        click_button "保存"
      end
      expect(status_code.to_s).to match(/200|302/)
      expect(page).not_to have_css("form#item-form")
    end

    it "#show" do
      visit "#{path}/#{item.id}"
      expect(status_code).to eq 200
      expect(page).to have_content(item.name)
    end

    it "#edit" do
      visit "#{path}/#{item.id}/edit"
      within "form#item-form" do
        fill_in "item[name]", with: "name2"
        click_button "保存"
      end
      expect(page).not_to have_css("form#item-form")
    end

    it "#delete" do
      visit "#{path}/#{item.id}/delete"
      within "form" do
        click_button "削除"
      end
      expect(page).not_to have_content(item.name)
    end
  end
end
