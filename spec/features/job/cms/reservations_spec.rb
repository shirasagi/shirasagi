require 'spec_helper'

describe "job_cms_reservations", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:item) { create :job_model, cur_site: site }
  let!(:index_path) { job_cms_reservations_path site }
  let!(:show_path) { job_cms_reservation_path site, item }
  let!(:delete_path) { delete_job_cms_reservation_path site, item }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      within ".list-items" do
        expect(page).to have_link(item.class_name)
      end
    end

    it "#show" do
      visit show_path
      within "#addon-basic" do
        expect(page).to have_text(item.class_name)
      end
    end

    it "#delete" do
      visit delete_path
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')
    end

    it "#delete_all" do
      visit index_path
      within ".list-items" do
        expect(page).to have_link(item.class_name)
      end

      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      within ".list-items" do
        expect(page).to have_no_link(item.class_name)
      end
    end
  end
end
