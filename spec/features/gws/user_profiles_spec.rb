require 'spec_helper'

describe "gws_user_profiles", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }

  context "with auth" do
    before { login_gws_user }

    it "#show" do
      visit gws_user_profile_path(site: site)
      expect(page).to have_content(user.name)

      # json
      visit gws_user_profile_path(site: site, format: :json)
      expect(page).to have_content(user.name)
    end
  end
end
