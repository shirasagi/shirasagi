require 'spec_helper'

describe "gws_affair2_admin_attendance_settings", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }

  let!(:user) { affair2.users.u3 }
  let!(:attendance) { affair2.attendance_settings.u3 }
  let!(:duty_setting) { attendance.duty_setting }
  let!(:leave_setting) { attendance.leave_setting }

  let!(:index_path) { gws_affair2_admin_user_attendance_settings_path site, user }
  let!(:show_path) { gws_affair2_admin_user_attendance_setting_path site, user, attendance }
  let!(:edit_path) { edit_gws_affair2_admin_user_attendance_setting_path site, user, attendance }
  let!(:delete_path) { delete_gws_affair2_admin_user_attendance_setting_path site, user, attendance }

  context "basic" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      within "table" do
        expect(page).to have_css("td", text: attendance.name)
        click_on attendance.name
      end
      within "#addon-basic" do
        expect(page).to have_css("dd", text: user.long_name)
        expect(page).to have_css("dd", text: attendance.duty_setting.name)
        expect(page).to have_css("dd", text: attendance.leave_setting.name)
      end
    end

    it "#show" do
      visit show_path
      within "#addon-basic" do
        expect(page).to have_css("dd", text: user.long_name)
        expect(page).to have_css("dd", text: attendance.duty_setting.name)
        expect(page).to have_css("dd", text: attendance.leave_setting.name)
      end
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
    end

    it "#delete" do
      visit delete_path
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end
  end
end
