require 'spec_helper'

describe "gws_survey", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:now) { Time.zone.now.beginning_of_minute }

  let!(:item1) do
    create(
      :gws_survey_form, state: "public", due_date: now + 1.day,
        readable_setting_range: "select", readable_member_ids: [user.id])
  end
  let!(:item2) do
    create(
      :gws_survey_form, state: "public", due_date: now + 2.days,
        readable_setting_range: "select", readable_member_ids: [user.id])
  end
  let!(:item3) do
    create(
      :gws_survey_form, state: "public", due_date: now + 3.days,
        readable_setting_range: "select", readable_member_ids: [user.id])
  end
  let!(:item4) do
    create(
      :gws_survey_form, state: "public", due_date: now + 4.days,
        readable_setting_range: "select", readable_member_ids: [user.id],
        answered_users_hash: { user.id.to_s => now })
  end
  let!(:item5) do
    create(
      :gws_survey_form, state: "public", due_date: now + 5.days,
        readable_setting_range: "select", readable_member_ids: [user.id],
        answered_users_hash: { user.id.to_s => now })
  end
  let!(:item6) do
    create(
      :gws_survey_form, state: "public", due_date: now + 6.days,
        readable_setting_range: "select", readable_member_ids: [user.id],
        answered_users_hash: { user.id.to_s => now })
  end
  let(:index_path) { gws_survey_main_path(site: site) }

  context "show default (site's both)" do
    before { login_gws_user }

    it do
      visit index_path
      within ".list-items" do
        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_link item3.name
        expect(page).to have_link item4.name
        expect(page).to have_link item5.name
        expect(page).to have_link item6.name
      end
    end
  end

  context "show unanswered" do
    before do
      login_gws_user
      site.survey_answered_state = "unanswered"
      site.update!
    end

    it do
      visit index_path
      within ".list-items" do
        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_link item3.name
        expect(page).to have_no_link item4.name
        expect(page).to have_no_link item5.name
        expect(page).to have_no_link item6.name
      end

      within ".index-search" do
        select I18n.t("gws/survey.options.answered_state.both"), from: "s[answered_state]"
        click_on I18n.t("ss.buttons.search")
      end

      within ".list-items" do
        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_link item3.name
        expect(page).to have_link item4.name
        expect(page).to have_link item5.name
        expect(page).to have_link item6.name
      end
    end
  end

  context "show answered" do
    before do
      login_gws_user
      site.survey_answered_state = "answered"
      site.update!
    end

    it do
      visit index_path
      within ".list-items" do
        expect(page).to have_no_link item1.name
        expect(page).to have_no_link item2.name
        expect(page).to have_no_link item3.name
        expect(page).to have_link item4.name
        expect(page).to have_link item5.name
        expect(page).to have_link item6.name
      end

      within ".index-search" do
        select I18n.t("gws/survey.options.answered_state.both"), from: "s[answered_state]"
        click_on I18n.t("ss.buttons.search")
      end

      within ".list-items" do
        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
        expect(page).to have_link item3.name
        expect(page).to have_link item4.name
        expect(page).to have_link item5.name
        expect(page).to have_link item6.name
      end
    end
  end
end
