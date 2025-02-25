require 'spec_helper'

describe "gws_affair2_book_time_cards", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:affair2) { gws_affair2 }
  let!(:index_path) { gws_affair2_book_form_main_path(site, "time_cards") }

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
      let(:group) { affair2.groups.g1_1_1 }

      it "#index" do
        visit index_path
        within ".gws-attendance .sheet" do
          expect(page).to have_css(".user-name", text: user.name)
          expect(page).to have_css(".group-name", text: group.trailing_name)
        end
      end
    end
  end
end
