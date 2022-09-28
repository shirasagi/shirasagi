require 'spec_helper'

describe "gws_schedule_group_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:group) { gws_user.groups.first }
  let(:index_path) { gws_schedule_group_plans_path site, group }

  before { login_gws_user }

  context "default 8 - 22" do
    it "#index" do
      visit index_path
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

  context "settting 6 - 24" do
    before do
      site.schedule_min_hour = 6
      site.schedule_max_hour = 24
      site.update
    end

    it "#index" do
      visit index_path
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
