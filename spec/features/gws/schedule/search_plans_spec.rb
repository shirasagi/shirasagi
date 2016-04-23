require 'spec_helper'

describe "gws_schedule_searc_plans", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_schedule_search_plans_path site }

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
      visit path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path

      within "form.search" do
        fill_in "s[keyword]", with: gws_user.name
        click_button "検索"
      end
      expect(page).to have_content(gws_user.name)
    end
  end
end
