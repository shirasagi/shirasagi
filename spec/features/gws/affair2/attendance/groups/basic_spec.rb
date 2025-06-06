require 'spec_helper'

describe "gws_affair2_leave_achieve", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:affair2) { gws_affair2 }

  let!(:attendance_date) { site.affair2_attendance_date }
  let!(:year_month) { attendance_date.strftime('%Y%m') }
  let!(:day) { attendance_date.day }

  context "denied with no attendance setting" do
    before { login_gws_user }

    it "#index" do
      visit gws_affair2_attendance_groups_main_path(site)
      expect(page).to have_text(I18n.t("gws/affair2.notice.no_attendance_setting", user: user.long_name))
    end
  end

  context "basic" do
    context "manager user" do
      let(:user) { affair2.users.u2 }

      before { login_user(user) }

      it "#index" do
        visit gws_affair2_attendance_groups_main_path(site)
        expect(current_path).to eq gws_affair2_attendance_groups_path(site, affair2.groups.g1_1, year_month, day)
        wait_for_js_ready

        within ".nav-menu.select-group" do
          expect(page).to have_selector("select[name=\"group\"] option", count: 4)
          expect(page).to have_css("select[name=\"group\"] option", text: affair2.groups.g1_1.name)
          expect(page).to have_css("select[name=\"group\"] option", text: affair2.groups.g1_1_1.name)
          expect(page).to have_css("select[name=\"group\"] option", text: affair2.groups.g1_1_2.name)
        end
        within ".attendance-box.daily" do
          within "tbody" do
            expect(page).to have_selector("tr", count: 2)
            expect(page).to have_text user.name
            expect(page).to have_text affair2.users.u12.name
          end
        end

        within ".nav-menu.select-group" do
          select affair2.groups.g1_1_1.name, from: "group"
        end
        expect(current_path).to eq gws_affair2_attendance_groups_path(site, affair2.groups.g1_1_1, year_month, day)
        wait_for_js_ready

        within ".attendance-box.daily" do
          within "tbody" do
            expect(page).to have_selector("tr", count: 2)
            expect(page).to have_text affair2.users.u3.name
            expect(page).to have_text affair2.users.u4.name
          end
        end

        within ".nav-menu.select-group" do
          select affair2.groups.g1_1_2.name, from: "group"
        end
        expect(current_path).to eq gws_affair2_attendance_groups_path(site, affair2.groups.g1_1_2, year_month, day)
        wait_for_js_ready

        within ".attendance-box.daily" do
          within "tbody" do
            expect(page).to have_selector("tr", count: 2)
            expect(page).to have_text affair2.users.u5.name
            expect(page).to have_text affair2.users.u6.name
          end
        end
      end
    end

    context "regular user" do
      let(:user) { affair2.users.u3 }

      before { login_user(user) }

      it "#index" do
        visit gws_affair2_attendance_groups_main_path(site)
        expect(current_path).to eq gws_affair2_attendance_groups_path(site, affair2.groups.g1_1_1, year_month, day)
        wait_for_js_ready

        within ".nav-menu.select-group" do
          expect(page).to have_selector("select[name=\"group\"] option", count: 2)
          expect(page).to have_css("select[name=\"group\"] option", text: affair2.groups.g1_1_1.name)
        end
        within ".attendance-box.daily" do
          within "tbody" do
            expect(page).to have_selector("tr", count: 2)
            expect(page).to have_text affair2.users.u3.name
            expect(page).to have_text affair2.users.u4.name
          end
        end
      end
    end
  end
end
