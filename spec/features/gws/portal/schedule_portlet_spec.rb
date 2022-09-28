require 'spec_helper'

describe "gws_portal_portlet", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:group) { gws_user.groups.first }
  let(:user_portal_path) { gws_portal_user_path(site: site, user: user) }
  let(:group_portal_path) { gws_portal_group_path(site: site, group: group) }

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
        within "footer.send" do
          click_on I18n.t("ss.buttons.cancel")
        end
        expect(current_path).to eq user_portal_path
      end
    end

    context "group portal" do
      it "back to index" do
        visit group_portal_path
        within ".portlets .gws-schedule-box" do
          click_on I18n.t("gws/schedule.links.add_plan")
        end
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
        within "footer.send" do
          click_on I18n.t("ss.buttons.cancel")
        end
        expect(current_path).to eq group_portal_path
      end
    end
  end

  context "day hours" do
    context "user portal" do
      context "default 8 - 22" do
        it do
          visit user_portal_path
          within ".portlets .gws-schedule-box" do
            within "#calendar-controller" do
              click_on I18n.t("datetime.prompts.day")
              expect(page).to have_no_css(".fc-widget-header[data-date*=\"00:00:00\"]")
              expect(page).to have_no_css(".fc-widget-header[data-date*=\"06:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"12:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"18:00:00\"]")
              expect(page).to have_no_css(".fc-widget-header[data-date*=\"23:00:00\"]")
            end
          end
        end
      end

      context "settting 6 - 24" do
        before do
          site.schedule_min_hour = 6
          site.schedule_max_hour = 24
          site.update
        end

        it do
          visit user_portal_path
          within ".portlets .gws-schedule-box" do
            within "#calendar-controller" do
              click_on I18n.t("datetime.prompts.day")
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
              click_on I18n.t("datetime.prompts.day")
              expect(page).to have_no_css(".fc-widget-header[data-date*=\"00:00:00\"]")
              expect(page).to have_no_css(".fc-widget-header[data-date*=\"06:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"12:00:00\"]")
              expect(page).to have_css(".fc-widget-header[data-date*=\"18:00:00\"]")
              expect(page).to have_no_css(".fc-widget-header[data-date*=\"23:00:00\"]")
            end
          end
        end
      end

      context "settting 6 - 24" do
        before do
          site.schedule_min_hour = 6
          site.schedule_max_hour = 24
          site.update
        end

        it do
          visit group_portal_path
          within ".portlets .gws-schedule-box" do
            within "#calendar-controller" do
              click_on I18n.t("datetime.prompts.day")
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
end
