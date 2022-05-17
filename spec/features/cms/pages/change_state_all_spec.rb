require 'spec_helper'

describe "cms_page_pages", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let!(:page1) { create(:cms_page) }
  let!(:page2) { create(:cms_page) }
  let!(:page3) { create(:cms_page) }

  context "change state all", js: true do
    before { login_cms_user }

    it do
      visit cms_pages_path(site)
      expect(page1.state).to eq "public"
      expect(page2.state).to eq "public"
      expect(page3.state).to eq "public"

      find('.list-head input[type="checkbox"]').set(true)
      within ".list-head-action-update" do
        click_button I18n.t('ss.links.make_them_close')
      end

      wait_for_ajax
      click_button I18n.t("ss.buttons.make_them_close")
      expect(current_path).to eq cms_pages_path(site)

      page1.reload
      page2.reload
      page3.reload
      expect(page1.state).to eq "closed"
      expect(page2.state).to eq "closed"
      expect(page3.state).to eq "closed"

      find('.list-head input[type="checkbox"]').set(true)
      within ".list-head-action-update" do
        click_button I18n.t('ss.links.make_them_public')
      end

      wait_for_ajax
      click_button I18n.t("ss.buttons.make_them_public")
      expect(current_path).to eq cms_pages_path(site)

      page1.reload
      page2.reload
      page3.reload
      expect(page1.state).to eq "public"
      expect(page2.state).to eq "public"
      expect(page3.state).to eq "public"
    end
  end
end
