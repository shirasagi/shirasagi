require 'spec_helper'

describe "gws_affair2_admin_users", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }
  let!(:index_path) { gws_affair2_admin_users_path site.id }

  context "basic" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      within ".list-items" do
        expect(page).to have_selector(".list-item", count: Gws::User.site(site).active.count)
      end
    end
  end
end
