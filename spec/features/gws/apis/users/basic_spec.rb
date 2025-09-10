require 'spec_helper'

describe "gws_apis_users", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_apis_users_path site }

  context "with auth" do
    before { login_gws_user }

    it "index" do
      visit path
      expect(status_code).to eq 200
      expect(page).to have_content(gws_user.name)

      click_on I18n.t('ss.buttons.search')
      expect(status_code).to eq 200
      expect(page).to have_content(gws_user.name)
    end
  end
end
