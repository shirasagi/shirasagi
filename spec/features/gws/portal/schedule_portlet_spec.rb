require 'spec_helper'

describe "gws_portal_portlet", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:group) { gws_user.groups.first }
  let(:user_portal_path) { gws_portal_user_path(site: site, user: user) }
  let(:group_portal_path) { gws_portal_group_path(site: site, group: group) }
  let!(:item1) { create :gws_schedule_plan }
  let!(:item2) { create :gws_schedule_plan, allday: 'allday' }

  before do
    login_gws_user
  end

  context "transition" do
    context "user portal" do
      it "back to index" do
        visit user_portal_path
        within ".portlets .gws-schedule-box" do
          click_on I18n.t("gws/schedule.links.add_plan")
        end
        wait_for_js_ready
        within ".nav-menu" do
          click_on I18n.t("ss.links.back_to_index")
        end
        expect(current_path).to eq user_portal_path
      end

      it "cancel" do
        visit user_portal_path
        within ".portlets .gws-schedule-box" do
          click_on I18n.t("gws/schedule.links.add_plan")
        end
        wait_for_js_ready
        within "footer.send" do
          click_on I18n.t("ss.buttons.cancel")
        end
        expect(current_path).to eq user_portal_path
      end

      it "click event" do
        visit user_portal_path
        first(".fc-content", text: item1.name).click
        expect(current_path).to eq gws_schedule_user_plan_path(site, gws_user, item1)
      end

      it "click allday event" do
        visit user_portal_path
        first(".fc-content", text: item2.name).click
        expect(current_path).to eq gws_schedule_user_plan_path(site, gws_user, item2)
      end
    end

    context "group portal" do
      it "back to index" do
        visit group_portal_path
        within ".portlets .gws-schedule-box" do
          click_on I18n.t("gws/schedule.links.add_plan")
        end
        wait_for_js_ready
        within ".nav-menu" do
          click_on I18n.t("ss.links.back_to_index")
        end
        expect(current_path).to eq group_portal_path
      end

      it "cancel" do
        visit group_portal_path
        within ".portlets .gws-schedule-box" do
          click_on I18n.t("gws/schedule.links.add_plan")
        end
        wait_for_js_ready
        within "footer.send" do
          click_on I18n.t("ss.buttons.cancel")
        end
        expect(current_path).to eq group_portal_path
      end

      it "click event" do
        visit group_portal_path
        first(".fc-content", text: item1.name).click
        expect(current_path).to eq gws_schedule_user_plan_path(site, gws_user, item1)
      end

      it "click allday event" do
        visit group_portal_path
        first(".fc-content", text: item2.name).click
        expect(current_path).to eq gws_schedule_user_plan_path(site, gws_user, item2)
      end
    end
  end

  context "schedule hours" do
    context "user portal" do
      context "default 8 - 22" do
        it do
          visit user_portal_path
          within ".portlets .gws-schedule-box" do
            within "#calendar-controller" do
              click_on I18n.t("datetime.prompts.day").downcase
              wait_for_js_ready

              expect(page).to have_no_css(".fc-widget-header[data-date*=\"00:00:00\"]")
              expect(page).to have_no_css(".fc-widget-header[data-date*=\"06:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"12:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"18:00:00\"]")
              expect(page).to have_no_css(".fc-widget-header[data-date*=\"23:00:00\"]")
            end
          end
        end
      end

      context "setting 6 - 24" do
        before do
          site.schedule_min_hour = 6
          site.schedule_max_hour = 24
          site.update
        end

        it do
          visit user_portal_path
          within ".portlets .gws-schedule-box" do
            within "#calendar-controller" do
              click_on I18n.t("datetime.prompts.day").downcase
              wait_for_js_ready

              expect(page).to have_no_css(".fc-widget-header[data-date*=\"00:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"06:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"12:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"18:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"23:00:00\"]")
            end
          end
        end
      end
    end

    context "group portal" do
      context "default 8 - 22" do
        it do
          visit group_portal_path
          within ".portlets .gws-schedule-box" do
            within "#calendar-controller" do
              click_on I18n.t("datetime.prompts.day").downcase
              expect(page).to have_no_css(".fc-widget-header[data-date*=\"00:00:00\"]")
              expect(page).to have_no_css(".fc-widget-header[data-date*=\"06:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"12:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"18:00:00\"]")
              expect(page).to have_no_css(".fc-widget-header[data-date*=\"23:00:00\"]")
            end
          end
        end
      end

      context "setting 6 - 24" do
        before do
          site.schedule_min_hour = 6
          site.schedule_max_hour = 24
          site.update
        end

        it do
          visit group_portal_path
          within ".portlets .gws-schedule-box" do
            within "#calendar-controller" do
              click_on I18n.t("datetime.prompts.day").downcase
              expect(page).to have_no_css(".fc-widget-header[data-date*=\"00:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"06:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"12:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"18:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"23:00:00\"]")
            end
          end
        end
      end
    end
  end

  context "schedule wday" do
    def first_wday_header
      all("th.fc-day-header").first[:class]
    end

    def last_wday_header
      all("th.fc-day-header").last[:class]
    end

    context "user portal" do
      context "default sunday" do
        it "#index" do
          visit user_portal_path
          within "#calendar-controller" do
            expect(first_wday_header).to include("fc-sun")
            expect(last_wday_header).to include("fc-sat")
          end
        end
      end

      context "setting monday" do
        before do
          site.schedule_first_wday = 1
          site.update
        end

        it "#index" do
          visit user_portal_path
          within "#calendar-controller" do
            expect(first_wday_header).to include("fc-mon")
            expect(last_wday_header).to include("fc-sun")
          end
        end
      end

      context "setting saturday" do
        before do
          site.schedule_first_wday = 6
          site.update
        end

        it "#index" do
          visit user_portal_path
          within "#calendar-controller" do
            expect(first_wday_header).to include("fc-sat")
            expect(last_wday_header).to include("fc-fri")
          end
        end
      end

      context "setting today" do
        before do
          site.schedule_first_wday = -1
          site.update
        end

        it "#index" do
          today = Time.zone.today
          fc_first = "fc-" + today.strftime("%a").downcase
          fc_last = "fc-" + today.advance(days: 6).strftime("%a").downcase

          visit user_portal_path
          within "#calendar-controller" do
            expect(first_wday_header).to include(fc_first)
            expect(last_wday_header).to include(fc_last)
          end
        end
      end
    end

    context "group portal" do
      context "default sunday" do
        it "#index" do
          visit group_portal_path
          within "#calendar-controller" do
            expect(first_wday_header).to include("fc-sun")
            expect(last_wday_header).to include("fc-sat")
          end
        end
      end

      context "setting monday" do
        before do
          site.schedule_first_wday = 1
          site.update
        end

        it "#index" do
          visit group_portal_path
          within "#calendar-controller" do
            expect(first_wday_header).to include("fc-mon")
            expect(last_wday_header).to include("fc-sun")
          end
        end
      end

      context "setting saturday" do
        before do
          site.schedule_first_wday = 6
          site.update
        end

        it "#index" do
          visit group_portal_path
          within "#calendar-controller" do
            expect(first_wday_header).to include("fc-sat")
            expect(last_wday_header).to include("fc-fri")
          end
        end
      end

      context "setting today" do
        before do
          site.schedule_first_wday = -1
          site.update
        end

        it "#index" do
          today = Time.zone.today
          fc_first = "fc-" + today.strftime("%a").downcase
          fc_last = "fc-" + today.advance(days: 6).strftime("%a").downcase

          visit group_portal_path
          within "#calendar-controller" do
            expect(first_wday_header).to include(fc_first)
            expect(last_wday_header).to include(fc_last)
          end
        end
      end
    end
  end
end
