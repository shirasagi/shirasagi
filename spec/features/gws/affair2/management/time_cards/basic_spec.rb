require 'spec_helper'

describe "gws_affair2_leave_achieve", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:affair2) { gws_affair2 }

  let!(:attendance_date) { site.affair2_attendance_date }
  let!(:year_month) { attendance_date.strftime('%Y%m') }

  context "allowed with no attendance setting" do
    before { login_gws_user }

    it "#index" do
      visit gws_affair2_management_main_path(site)
      expect(page).to have_no_text(I18n.t("gws/affair2.notice.no_attendance_setting", user: user.long_name))
    end
  end

  context "basic" do
    context "manager user" do
      let(:user) { affair2.users.u2 }

      before { login_user(user) }

      it "#index" do
        visit gws_affair2_management_main_path(site)
        expect(current_path).to eq gws_affair2_management_time_cards_path(site, affair2.groups.g1_1, year_month)
        wait_for_js_ready

        within ".nav-menu.select-group" do
          expect(page).to have_selector("select[name=\"group\"] option", count: 4)
          expect(page).to have_css("select[name=\"group\"] option", text: affair2.groups.g1_1.name)
          expect(page).to have_css("select[name=\"group\"] option", text: affair2.groups.g1_1_1.name)
          expect(page).to have_css("select[name=\"group\"] option", text: affair2.groups.g1_1_2.name)
        end
        within "table.index tbody" do
          expect(page).to have_selector("tr", count: 2)
          expect(page).to have_text user.long_name
          expect(page).to have_text affair2.users.u12.long_name
        end

        within ".nav-menu.select-group" do
          select affair2.groups.g1_1_1.name, from: "group"
        end
        expect(current_path).to eq gws_affair2_management_time_cards_path(site, affair2.groups.g1_1_1, year_month)
        wait_for_js_ready

        within "table.index tbody" do
          expect(page).to have_selector("tr", count: 2)
          expect(page).to have_text affair2.users.u3.long_name
          expect(page).to have_text affair2.users.u4.long_name
        end

        within ".nav-menu.select-group" do
          select affair2.groups.g1_1_2.name, from: "group"
        end
        expect(current_path).to eq gws_affair2_management_time_cards_path(site, affair2.groups.g1_1_2, year_month)
        wait_for_js_ready

        within "table.index tbody" do
          expect(page).to have_selector("tr", count: 2)
          expect(page).to have_text affair2.users.u5.long_name
          expect(page).to have_text affair2.users.u6.long_name
        end
      end
    end

    context "manager user" do
      let(:user) { affair2.users.u12 }

      before { login_user(user) }

      it "#index" do
        visit gws_affair2_management_main_path(site)
        expect(current_path).to eq gws_affair2_management_time_cards_path(site, affair2.groups.g1_1, year_month)
        wait_for_js_ready

        within ".nav-menu.select-group" do
          expect(page).to have_selector("select[name=\"group\"] option", count: 7)
          expect(page).to have_css("select[name=\"group\"] option", text: affair2.groups.g1_1.name)
          expect(page).to have_css("select[name=\"group\"] option", text: affair2.groups.g1_1_1.name)
          expect(page).to have_css("select[name=\"group\"] option", text: affair2.groups.g1_1_2.name)
          expect(page).to have_css("select[name=\"group\"] option", text: affair2.groups.g1_2.name)
          expect(page).to have_css("select[name=\"group\"] option", text: affair2.groups.g1_2_1.name)
          expect(page).to have_css("select[name=\"group\"] option", text: affair2.groups.g1_2_2.name)
        end
        within "table.index tbody" do
          expect(page).to have_selector("tr", count: 2)
          expect(page).to have_text user.long_name
          expect(page).to have_text affair2.users.u2.long_name
        end

        within ".nav-menu.select-group" do
          select affair2.groups.g1_2.name, from: "group"
        end
        expect(current_path).to eq gws_affair2_management_time_cards_path(site, affair2.groups.g1_2, year_month)
        wait_for_js_ready

        within "table.index tbody" do
          expect(page).to have_selector("tr", count: 2)
          expect(page).to have_text user.long_name
          expect(page).to have_text affair2.users.u7.long_name
        end
      end
    end
  end
end
