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
          click_on I18n.t('ss.buttons.download')
        end

        within "#item-form" do
          click_on I18n.t("ss.links.download")
        end
        wait_for_download

        csv = ::CSV.read(downloads.first, headers: true)
        expect(csv[0][0]).not_to be_nil
      end
    end
  end
end
