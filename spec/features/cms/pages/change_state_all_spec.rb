require 'spec_helper'

describe "cms_page_pages", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
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

      wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action-update" do
        click_button I18n.t('ss.links.make_them_close')
      end

      wait_for_js_ready
      click_button I18n.t("ss.buttons.make_them_close")
      wait_for_notice I18n.t("ss.notice.changed")

      page1.reload
      page2.reload
      page3.reload
      expect(page1.state).to eq "closed"
      expect(page2.state).to eq "closed"
      expect(page3.state).to eq "closed"

      expect(page1.backups.size).to eq 2
      expect(page1.backups.first.user_id).to eq user.id

      expect(page2.backups.size).to eq 2
      expect(page2.backups.first.user_id).to eq user.id

      expect(page3.backups.size).to eq 2
      expect(page3.backups.first.user_id).to eq user.id

      wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action-update" do
        click_button I18n.t('ss.links.make_them_public')
      end

      wait_for_js_ready
      click_button I18n.t("ss.buttons.make_them_public")
      wait_for_notice I18n.t("ss.notice.changed")

      page1.reload
      page2.reload
      page3.reload
      expect(page1.state).to eq "public"
      expect(page2.state).to eq "public"
      expect(page3.state).to eq "public"

      expect(page1.backups.size).to eq 3
      expect(page1.backups.first.user_id).to eq user.id

      expect(page2.backups.size).to eq 3
      expect(page2.backups.first.user_id).to eq user.id

      expect(page3.backups.size).to eq 3
      expect(page3.backups.first.user_id).to eq user.id
    end
  end
end
