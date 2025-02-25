require 'spec_helper'

describe "gws_affair2_book_holiday_overtime", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:affair2) { gws_affair2 }
  let!(:index_path) { gws_affair2_book_form_main_path(site, "holiday_overtime") }

  context "denied with no attendance setting" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(page).to have_text(I18n.t("gws/affair2.notice.no_attendance_setting", user: user.long_name))
    end
  end

  context "basic" do
    before { login_user(user) }

    context "regular user" do
      let(:user) { affair2.users.u3 }

      it "#index" do
        visit index_path
        expect(page).to have_css(".gws-attendance .sheet")
      end
    end
  end
end
