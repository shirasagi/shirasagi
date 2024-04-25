require 'spec_helper'

describe "gws_schedule_user_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:item) { create :gws_schedule_facility_plan }
  let(:index_path) { gws_schedule_user_plans_path site, gws_user }
  let(:new_path) { new_gws_schedule_user_plan_path site, gws_user }
  let(:show_path) { gws_schedule_user_plan_path site, gws_user, item }
  let(:edit_path) { edit_gws_schedule_user_plan_path site, gws_user, item }
  let(:delete_path) { soft_delete_gws_schedule_user_plan_path site, gws_user, item }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      wait_for_js_ready
      expect(page).to have_content(item.name)
    end

    it "#events" do
      sdate = item.start_at.to_date.beginning_of_month
      edate = item.end_at.to_date.beginning_of_month + 1.month
      visit "#{index_path}/events.json?s[start]=#{sdate}&s[end]=#{edate}"
      expect(page.body).to have_content(item.name)
    end

    it "#new" do
      visit new_path
      wait_for_js_ready
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_js_ready
      wait_for_notice I18n.t('ss.notice.saved')
    end

    it "#show" do
      visit show_path
      wait_for_js_ready
      expect(page).to have_content(item.name)
    end

    it "#edit" do
      visit edit_path
      wait_for_js_ready
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_js_ready
      wait_for_notice I18n.t('ss.notice.saved')
    end

    it "#delete" do
      visit index_path
      wait_for_js_ready
      first('span.fc-title', text: item.name).click
      wait_for_js_ready
      expect(current_path).to eq show_path
      within ".nav-menu" do
        click_link I18n.t('ss.links.delete')
      end
      wait_for_js_ready
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_js_ready
      expect(current_path).to eq index_path
      wait_for_notice I18n.t('ss.notice.deleted')
    end

    context 'with gws_schedule_facility_plan_few_days' do
      let!(:item) { create :gws_schedule_facility_plan_few_days }

      it "#index" do
        visit index_path
        wait_for_js_ready
        expect(page).to have_content(item.name)
      end

      it "#events" do
        sdate = item.start_on
        edate = item.end_on
        visit "#{index_path}/events.json?s[start]=#{sdate}&s[end]=#{edate}"
        expect(page.body).to have_content(item.name)
      end

      it "#new" do
        visit new_path
        wait_for_js_ready
        within "form#item-form" do
          fill_in "item[name]", with: "name"
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_js_ready
        wait_for_notice I18n.t('ss.notice.saved')
      end

      it "#show" do
        visit show_path
        wait_for_js_ready
        expect(page).to have_content(item.name)
      end

      it "#edit" do
        visit edit_path
        wait_for_js_ready
        within "form#item-form" do
          fill_in "item[name]", with: "modify"
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_js_ready
        wait_for_notice I18n.t('ss.notice.saved')
      end

      it "#delete" do
        visit index_path
        wait_for_js_ready

        first('span.fc-title', text: item.name).click
        wait_for_js_ready

        expect(current_path).to eq show_path
        within ".nav-menu" do
          click_link I18n.t('ss.links.delete')
        end
        wait_for_js_ready

        within "form#item-form" do
          click_button I18n.t('ss.buttons.delete')
        end
        wait_for_js_ready

        expect(current_path).to eq index_path
        wait_for_notice I18n.t('ss.notice.deleted')
      end
    end
  end
end
