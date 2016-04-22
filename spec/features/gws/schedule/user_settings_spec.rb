require 'spec_helper'

describe "gws_schedule_user_settings", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_schedule_user_setting_path site }

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
    let(:item) { gws_user.groups.in_group(site).first }

    before { login_gws_user }

    it "#show" do
      visit path
      expect(status_code).to eq 200
      expect(page).to have_content(item.name)
    end

    it "#edit" do
      visit "#{path}/edit"
      within "form#item-form" do
        uncheck("tab-g-#{item.id}")
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(page).not_to have_css("form#item-form")
      expect(page).not_to have_content(item.name)
    end
  end
end
