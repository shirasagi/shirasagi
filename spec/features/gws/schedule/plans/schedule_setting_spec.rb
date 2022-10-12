require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:index_path) { gws_schedule_plans_path site }

  before { login_gws_user }

  context "schedule hours" do
    context "default 8 - 22" do
      it "#index" do
        visit index_path
        within "#calendar" do
          click_on I18n.t("gws/schedule.options.interval.daily", locale: I18n.default_locale)
        end
        within ".fc-agenda-view" do
          expect(page).to have_no_css("tr[data-time=\"00:00:00\"]")
          expect(page).to have_no_css("tr[data-time=\"00:30:00\"]")
          expect(page).to have_no_css("tr[data-time=\"06:00:00\"]")
          expect(page).to have_no_css("tr[data-time=\"06:30:00\"]")
          expect(page).to have_css("tr[data-time=\"12:00:00\"]")
          expect(page).to have_css("tr[data-time=\"12:30:00\"]")
          expect(page).to have_css("tr[data-time=\"18:00:00\"]")
          expect(page).to have_css("tr[data-time=\"18:30:00\"]")
          expect(page).to have_no_css("tr[data-time=\"23:00:00\"]")
          expect(page).to have_no_css("tr[data-time=\"23:30:00\"]")
        end
      end
    end

    context "setting 6 - 24" do
      before do
        site.schedule_min_hour = 6
        site.schedule_max_hour = 24
        site.update
      end

      it "#index" do
        visit index_path
        within "#calendar" do
          click_on I18n.t("gws/schedule.options.interval.daily", locale: I18n.default_locale)
        end
        within ".fc-agenda-view" do
          expect(page).to have_no_css("tr[data-time=\"00:00:00\"]")
          expect(page).to have_no_css("tr[data-time=\"00:30:00\"]")
          expect(page).to have_css("tr[data-time=\"06:00:00\"]")
          expect(page).to have_css("tr[data-time=\"06:30:00\"]")
          expect(page).to have_css("tr[data-time=\"12:00:00\"]")
          expect(page).to have_css("tr[data-time=\"12:30:00\"]")
          expect(page).to have_css("tr[data-time=\"18:00:00\"]")
          expect(page).to have_css("tr[data-time=\"18:30:00\"]")
          expect(page).to have_css("tr[data-time=\"23:00:00\"]")
          expect(page).to have_css("tr[data-time=\"23:30:00\"]")
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

    context "default sunday" do
      it "#index" do
        visit index_path
        within ".fc-head-container" do
          expect(first_wday_header).to include("fc-sun")
          expect(last_wday_header).to include("fc-sat")
        end
        within "#calendar" do
          click_on I18n.t("gws/schedule.options.interval.weekly", locale: I18n.default_locale)
        end
        within ".fc-head-container" do
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
        visit index_path
        within ".fc-head-container" do
          expect(first_wday_header).to include("fc-mon")
          expect(last_wday_header).to include("fc-sun")
        end
        within "#calendar" do
          click_on I18n.t("gws/schedule.options.interval.weekly", locale: I18n.default_locale)
        end
        within ".fc-head-container" do
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
        visit index_path
        within ".fc-head-container" do
          expect(first_wday_header).to include("fc-sat")
          expect(last_wday_header).to include("fc-fri")
        end
        within "#calendar" do
          click_on I18n.t("gws/schedule.options.interval.weekly", locale: I18n.default_locale)
        end
        within ".fc-head-container" do
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

        visit index_path
        within ".fc-head-container" do
          expect(first_wday_header).to include(fc_first)
          expect(last_wday_header).to include(fc_last)
        end
        within "#calendar" do
          click_on I18n.t("gws/schedule.options.interval.weekly", locale: I18n.default_locale)
        end
        within ".fc-head-container" do
          expect(first_wday_header).to include(fc_first)
          expect(last_wday_header).to include(fc_last)
        end
      end
    end
  end
end
