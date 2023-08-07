require 'spec_helper'

describe "gws_workload_admins", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:index_path) { gws_workload_admins_path site }
  let(:new_path) { new_gws_workload_admin_path site }
  let(:show_path) { gws_workload_admin_path site, item }
  let(:edit_path) { edit_gws_workload_admin_path site, item }
  let(:delete_path) { soft_delete_gws_workload_admin_path site, item }

  let(:item) { create :gws_workload_work }
  let(:name) { unique_id }
  let(:due_date) { I18n.l(Time.zone.today + 14, format: :picker) }
  let(:due_start_on) { I18n.l(Time.zone.today, format: :picker) }
  let(:due_end_on) { I18n.l(Time.zone.today + 7, format: :picker) }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      item
      visit index_path
      expect(page).to have_content(item.name)
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[due_date]", with: due_date
        fill_in "item[due_start_on]", with: due_start_on
        fill_in "item[due_end_on]", with: due_end_on
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      within "#addon-basic" do
        expect(page).to have_css("dd", text: name)
        expect(page).to have_css("dd", text: site.fiscal_year)
        expect(page).to have_css("dd", text: due_date)
        expect(page).to have_css("dd", text: due_start_on)
        expect(page).to have_css("dd", text: due_end_on)
      end
    end

    it "#show" do
      visit show_path
      expect(page).to have_content(item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      within "#addon-basic" do
        expect(page).to have_css("dd", text: name)
      end
    end

    it "#delete" do
      visit delete_path
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')
    end
  end
end
