require 'spec_helper'

describe "gws_apis_groups", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_apis_groups_path site }

  it "without login" do
    visit path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_gws_user }

    it "index" do
      visit path
      expect(status_code).to eq 200
      expect(page).to have_content(gws_user.groups.first.trailing_name)

      fill_in 's[keyword]', with: gws_user.groups.first.name
      click_on "検索"
      expect(status_code).to eq 200
      expect(page).to have_content(gws_user.groups.first.name)
    end
  end
end
