require 'spec_helper'

describe "job_sys_tasks", type: :feature, dbscope: :example, js: true do
  let!(:item) { create :ss_task }
  let!(:index_path) { job_sys_tasks_path }
  let!(:show_path) { job_sys_task_path item }
  let!(:delete_path) { delete_job_sys_task_path item }

  context "basic crud" do
    before { login_sys_user }

    it "#index" do
      visit index_path
      within ".list-items" do
        expect(page).to have_link(item.name)
      end
    end

    it "#show" do
      visit show_path
      within "#addon-basic" do
        expect(page).to have_text(item.name)
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
        expect(page).to have_link(item.name)
      end

      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        page.accept_alert do
          click_on I18n.t("ss.buttons.delete")
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      within ".list-items" do
        expect(page).to have_no_link(item.name)
      end
    end
  end
end
