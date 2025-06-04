require 'spec_helper'

describe "gws_affair2_time_cards", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }

  let(:month) do
    month = Time.zone.parse("2025/1/1")
    month = month.advance(minutes: site.affair2_time_changed_minute)
    month
  end

  context "basic" do
    context "regular user" do
      let(:user) { affair2.users.u3 }

      before { login_user(user) }

      it do
        visit gws_affair2_attendance_main_path site

        within ".attendance-box.monthly" do
          within ".nav-group" do
            expect(page).to have_no_link(I18n.t('ss.buttons.setting'))
          end
        end
      end
    end

    context "lotation user" do
      let(:user) { affair2.users.u5 }

      before { login_user(user) }

      it do
        visit gws_affair2_attendance_main_path site

        within ".attendance-box.monthly" do
          within ".time-card-error" do
            expect(page).to have_text(I18n.t("gws/affair2.time_card_errors.regular_open"))
          end
        end

        within ".attendance-box.monthly" do
          within ".nav-group" do
            expect(page).to have_link(I18n.t('ss.buttons.setting'))
            click_on I18n.t('ss.buttons.setting')
          end
        end
      end
    end
  end
end
