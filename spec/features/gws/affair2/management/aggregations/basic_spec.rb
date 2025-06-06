require 'spec_helper'

describe "gws_affair2_management_aggregations", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:affair2) { gws_affair2 }

  context "basic" do
    context "admin user" do
      before { login_gws_user }

      it "#index" do
        visit gws_affair2_management_main_path(site)
        wait_for_js_ready

        # regular
        within "#navi .current-navi" do
          click_on I18n.t("modules.gws/affair2/management/time_card")
        end
        wait_for_js_ready

        within ".aggregation-monthly" do
          expect(page).to have_css(".attendance-box-title", text: I18n.t("gws/affair2.options.employee_type.regular"))
          expect(page).to have_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_works"))
          expect(page).to have_no_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_leave"))
        end

        ## regular works
        within ".gws-schedule-tabs" do
          click_on I18n.t("gws/affair2.views.monthly_works")
        end
        wait_for_js_ready

        within ".aggregation-monthly" do
          expect(page).to have_css(".attendance-box-title", text: I18n.t("gws/affair2.options.employee_type.regular"))
          expect(page).to have_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_works"))
          expect(page).to have_no_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_leave"))
        end

        ## regular leave
        within ".gws-schedule-tabs" do
          click_on I18n.t("gws/affair2.views.monthly_leave")
        end
        wait_for_js_ready

        within ".aggregation-monthly" do
          expect(page).to have_css(".attendance-box-title", text: I18n.t("gws/affair2.options.employee_type.regular"))
          expect(page).to have_no_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_works"))
          expect(page).to have_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_leave"))
        end

        # regular
        within "#navi .current-navi" do
          click_on I18n.t("gws/affair2.options.employee_type.regular")
        end
        wait_for_js_ready

        within ".aggregation-monthly" do
          expect(page).to have_css(".attendance-box-title", text: I18n.t("gws/affair2.options.employee_type.regular"))
          expect(page).to have_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_works"))
          expect(page).to have_no_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_leave"))
        end

        ## regular works
        within ".gws-schedule-tabs" do
          click_on I18n.t("gws/affair2.views.monthly_works")
        end
        wait_for_js_ready

        within ".aggregation-monthly" do
          expect(page).to have_css(".attendance-box-title", text: I18n.t("gws/affair2.options.employee_type.regular"))
          expect(page).to have_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_works"))
          expect(page).to have_no_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_leave"))
        end

        ## regular leave
        within ".gws-schedule-tabs" do
          click_on I18n.t("gws/affair2.views.monthly_leave")
        end
        wait_for_js_ready

        within ".aggregation-monthly" do
          expect(page).to have_css(".attendance-box-title", text: I18n.t("gws/affair2.options.employee_type.regular"))
          expect(page).to have_no_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_works"))
          expect(page).to have_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_leave"))
        end

        # temporary_staff1
        within "#navi .current-navi" do
          click_on I18n.t("gws/affair2.options.employee_type.temporary_staff1")
        end
        wait_for_js_ready

        within ".aggregation-monthly" do
          expect(page).to have_css(".attendance-box-title", text: I18n.t("gws/affair2.options.employee_type.temporary_staff1"))
          expect(page).to have_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_works"))
          expect(page).to have_no_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_leave"))
        end

        ## temporary_staff1 works
        within ".gws-schedule-tabs" do
          click_on I18n.t("gws/affair2.views.monthly_works")
        end
        wait_for_js_ready

        within ".aggregation-monthly" do
          expect(page).to have_css(".attendance-box-title", text: I18n.t("gws/affair2.options.employee_type.temporary_staff1"))
          expect(page).to have_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_works"))
          expect(page).to have_no_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_leave"))
        end

        ## temporary_staff1 leave
        within ".gws-schedule-tabs" do
          click_on I18n.t("gws/affair2.views.monthly_leave")
        end
        wait_for_js_ready

        within ".aggregation-monthly" do
          expect(page).to have_css(".attendance-box-title", text: I18n.t("gws/affair2.options.employee_type.temporary_staff1"))
          expect(page).to have_no_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_works"))
          expect(page).to have_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_leave"))
        end

        # temporary_staff2
        within "#navi .current-navi" do
          click_on I18n.t("gws/affair2.options.employee_type.temporary_staff2")
        end
        wait_for_js_ready

        within ".aggregation-monthly" do
          expect(page).to have_css(".attendance-box-title", text: I18n.t("gws/affair2.options.employee_type.temporary_staff2"))
          expect(page).to have_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_works"))
          expect(page).to have_no_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_leave"))
        end

        ## temporary_staff2 works
        within ".gws-schedule-tabs" do
          click_on I18n.t("gws/affair2.views.monthly_works")
        end
        wait_for_js_ready

        within ".aggregation-monthly" do
          expect(page).to have_css(".attendance-box-title", text: I18n.t("gws/affair2.options.employee_type.temporary_staff2"))
          expect(page).to have_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_works"))
          expect(page).to have_no_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_leave"))
        end

        ## temporary_staff2 leave
        within ".gws-schedule-tabs" do
          click_on I18n.t("gws/affair2.views.monthly_leave")
        end
        wait_for_js_ready

        within ".aggregation-monthly" do
          expect(page).to have_css(".attendance-box-title", text: I18n.t("gws/affair2.options.employee_type.temporary_staff2"))
          expect(page).to have_no_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_works"))
          expect(page).to have_css(".current .tab-name", text: I18n.t("gws/affair2.views.monthly_leave"))
        end
      end
    end
  end
end
