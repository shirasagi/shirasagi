require 'spec_helper'

describe "cms_sites", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:index_path) { cms_site_path site.id }

  context "basic crud" do
    before { login_cms_user }

    it do
      visit index_path
      expect(status_code).to eq 200

      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      site.reload
      expect(site.name).to eq "modify"
    end
  end
end
