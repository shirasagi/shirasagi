require 'spec_helper'

describe "cms_sites" do
  subject(:site) { cms_site }
  subject(:index_path) { cms_site_path site.id }
  subject(:edit_path) { edit_cms_site_path site.id }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
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
  end
end
