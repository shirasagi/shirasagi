require 'spec_helper'

describe "gws_affair2_book_time_cards", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }
  let!(:time) { Time.zone.parse("2024/10/1 8:00") }

  around do |example|
    travel_to(time) { example.run }
  end

  context "basic" do
    before { login_user(user) }

    context "regular user" do
      let(:user) { affair2.users.u3 }
      let(:group) { affair2.groups.g1_1_1 }

      it "#index" do
        # time_card
        visit gws_affair2_attendance_main_path site

        ## enter
        within ".attendance-box.today" do
          within ".action .enter" do
            page.accept_alert do
              click_on I18n.t("gws/attendance.buttons.punch")
            end
          end
        end
        wait_for_notice I18n.t("gws/attendance.notice.punched")

        ## leave
        within ".attendance-box.today" do
          within ".action .leave" do
            page.accept_alert do
              click_on I18n.t("gws/attendance.buttons.punch")
            end
          end
        end
        wait_for_notice I18n.t("gws/attendance.notice.punched")

        visit gws_affair2_book_form_main_path(site, "time_cards")
        within ".gws-attendance .sheet" do
          expect(page).to have_css(".fiscal-year", text: "2024年度")
          within ".attendance" do
            within "thead" do
              expect(all("td").size).to eq 6
              expect(all("td")[0]).to have_text("10月")
              expect(all("td")[1]).to have_text("11月")
              expect(all("td")[2]).to have_text("12月")
              expect(all("td")[3]).to have_text("1月")
              expect(all("td")[4]).to have_text("2月")
              expect(all("td")[5]).to have_text("3月")
            end
            within "tbody" do
              expect(page).to have_selector("img.circle", count: 1)
              expect(all("td")[0]).to have_text("1日")
              expect(all("td")[0]).to have_css("img.circle")
            end
          end
        end
      end
    end
  end
end
