require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:index_path) { gws_schedule_plans_path site }

  before { login_gws_user }

  context "default 8 - 22" do
    it "#index" do
      visit index_path
      within "#calendar" do
        click_on I18n.t("datetime.prompts.day")
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

  context "settting 6 - 24" do
    before do
      site.schedule_min_hour = 6
      site.schedule_max_hour = 24
      site.update
    end

    it "#index" do
      visit index_path
      within "#calendar" do
        click_on I18n.t("datetime.prompts.day")
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
