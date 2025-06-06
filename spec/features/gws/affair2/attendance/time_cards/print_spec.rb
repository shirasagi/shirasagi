require 'spec_helper'

describe "gws_affair2_time_cards", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }

  context "basic" do
    context "regular user" do
      let(:user) { affair2.users.u3 }

      before { login_user(user) }

      it "#index" do
        visit gws_affair2_attendance_main_path site
        within ".nav-group" do
          click_on I18n.t('ss.buttons.print')
        end

        expect(page).to have_css("#page.print-preview")
      end
    end
  end
end
