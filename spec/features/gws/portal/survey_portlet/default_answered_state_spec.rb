require 'spec_helper'

describe "gws_portal_survey", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }

  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:item1) do
    create(
      :gws_survey_form, state: "public", due_date: now + 1.day,
        readable_setting_range: "select", readable_member_ids: [user.id],
        answered_users_hash: { user.id.to_s => now })
  end
  let!(:item2) do
    create(
      :gws_survey_form, state: "public", due_date: now + 2.days,
        readable_setting_range: "select", readable_member_ids: [user.id],
        answered_users_hash: { user.id.to_s => now })
  end
  let!(:item3) do
    create(
      :gws_survey_form, state: "public", due_date: now + 3.days,
        readable_setting_range: "select", readable_member_ids: [user.id],
        answered_users_hash: { user.id.to_s => now })
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
  let!(:item7) do
    create(
      :gws_survey_form, state: "public", due_date: now + 7.days,
        readable_setting_range: "select", readable_member_ids: [user.id])
  end
  let!(:item8) do
    create(
      :gws_survey_form, state: "public", due_date: now + 8.days,
        readable_setting_range: "select", readable_member_ids: [user.id])
  end
  let!(:item9) do
    create(
      :gws_survey_form, state: "public", due_date: now + 9.days,
        readable_setting_range: "select", readable_member_ids: [user.id])
  end
  let!(:item10) do
    create(
      :gws_survey_form, state: "public", due_date: now + 10.days,
        readable_setting_range: "select", readable_member_ids: [user.id])
  end
  let!(:item11) do
    create(
      :gws_survey_form, state: "public", due_date: now + 11.days,
        readable_setting_range: "select", readable_member_ids: [user.id])
  end
  let!(:item12) do
    create(
      :gws_survey_form, state: "public", due_date: now + 12.days,
        readable_setting_range: "select", readable_member_ids: [user.id])
  end

  before do
    login_gws_user
  end

  context "default both" do
    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')

      # destroy default portlet
      wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      # create portlet
      click_on I18n.t('ss.links.new')
      within ".main-box" do
        click_on I18n.t('gws/portal.portlets.survey.name')
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # visit portal agein
      visit gws_portal_user_path(site: site, user: user)
      within ".gws-portlets" do
        within ".portlets .gws-survey" do
          expect(page).to have_css(".list-item", text: item1.name)
          expect(page).to have_css(".list-item", text: item2.name)
          expect(page).to have_css(".list-item", text: item3.name)
          expect(page).to have_css(".list-item", text: item4.name)
          expect(page).to have_css(".list-item", text: item5.name)
          expect(page).to have_no_css(".list-item", text: item6.name)
          expect(page).to have_no_css(".list-item", text: item7.name)
          expect(page).to have_no_css(".list-item", text: item8.name)
          expect(page).to have_no_css(".list-item", text: item9.name)
          expect(page).to have_no_css(".list-item", text: item10.name)
          expect(page).to have_no_css(".list-item", text: item11.name)
          expect(page).to have_no_css(".list-item", text: item12.name)
        end
        # wait for ajax completion
        expect(page).to have_no_css('.fc-loading')
        expect(page).to have_no_css('.ss-base-loading')

        within ".portlets .gws-survey" do
          click_on I18n.t("ss.links.more")
        end
      end

      within ".index" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        expect(page).to have_css(".list-item", text: item3.name)
        expect(page).to have_css(".list-item", text: item4.name)
        expect(page).to have_css(".list-item", text: item5.name)
        expect(page).to have_css(".list-item", text: item6.name)
        expect(page).to have_css(".list-item", text: item7.name)
        expect(page).to have_css(".list-item", text: item8.name)
        expect(page).to have_css(".list-item", text: item9.name)
        expect(page).to have_css(".list-item", text: item10.name)
        expect(page).to have_css(".list-item", text: item11.name)
        expect(page).to have_css(".list-item", text: item12.name)
      end
    end
  end

  context "default unanswered" do
    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')

      # destroy default portlet
      wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      # create portlet
      click_on I18n.t('ss.links.new')
      within ".main-box" do
        click_on I18n.t('gws/portal.portlets.survey.name')
      end
      within 'form#item-form' do
        select I18n.t("gws/survey.options.answered_state.unanswered"), from: "item[survey_answered_state]"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # visit portal agein
      visit gws_portal_user_path(site: site, user: user)
      within ".gws-portlets" do
        within ".portlets .gws-survey" do
          expect(page).to have_no_css(".list-item", text: item1.name)
          expect(page).to have_no_css(".list-item", text: item2.name)
          expect(page).to have_no_css(".list-item", text: item3.name)
          expect(page).to have_no_css(".list-item", text: item4.name)
          expect(page).to have_no_css(".list-item", text: item5.name)
          expect(page).to have_no_css(".list-item", text: item6.name)
          expect(page).to have_css(".list-item", text: item7.name)
          expect(page).to have_css(".list-item", text: item8.name)
          expect(page).to have_css(".list-item", text: item9.name)
          expect(page).to have_css(".list-item", text: item10.name)
          expect(page).to have_css(".list-item", text: item11.name)
          expect(page).to have_no_css(".list-item", text: item12.name)
        end
        # wait for ajax completion
        expect(page).to have_no_css('.fc-loading')
        expect(page).to have_no_css('.ss-base-loading')

        within ".portlets .gws-survey" do
          click_on I18n.t("ss.links.more")
        end
      end

      within ".index" do
        expect(page).to have_no_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)
        expect(page).to have_no_css(".list-item", text: item3.name)
        expect(page).to have_no_css(".list-item", text: item4.name)
        expect(page).to have_no_css(".list-item", text: item5.name)
        expect(page).to have_no_css(".list-item", text: item6.name)
        expect(page).to have_css(".list-item", text: item7.name)
        expect(page).to have_css(".list-item", text: item8.name)
        expect(page).to have_css(".list-item", text: item9.name)
        expect(page).to have_css(".list-item", text: item10.name)
        expect(page).to have_css(".list-item", text: item11.name)
        expect(page).to have_css(".list-item", text: item12.name)
      end
    end
  end

  context "default answered" do
    it do
      visit gws_portal_user_path(site: site, user: user)
      click_on I18n.t('gws/portal.links.manage_portlets')

      # destroy default portlet
      wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action" do
        page.accept_alert do
          click_button I18n.t('ss.buttons.delete')
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      # create portlet
      click_on I18n.t('ss.links.new')
      within ".main-box" do
        click_on I18n.t('gws/portal.portlets.survey.name')
      end
      within 'form#item-form' do
        select I18n.t("gws/survey.options.answered_state.answered"), from: "item[survey_answered_state]"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      # visit portal agein
      visit gws_portal_user_path(site: site, user: user)
      within ".gws-portlets" do
        within ".portlets .gws-survey" do
          expect(page).to have_css(".list-item", text: item1.name)
          expect(page).to have_css(".list-item", text: item2.name)
          expect(page).to have_css(".list-item", text: item3.name)
          expect(page).to have_css(".list-item", text: item4.name)
          expect(page).to have_css(".list-item", text: item5.name)
          expect(page).to have_no_css(".list-item", text: item6.name)
          expect(page).to have_no_css(".list-item", text: item7.name)
          expect(page).to have_no_css(".list-item", text: item8.name)
          expect(page).to have_no_css(".list-item", text: item9.name)
          expect(page).to have_no_css(".list-item", text: item10.name)
          expect(page).to have_no_css(".list-item", text: item11.name)
          expect(page).to have_no_css(".list-item", text: item12.name)
        end
        # wait for ajax completion
        expect(page).to have_no_css('.fc-loading')
        expect(page).to have_no_css('.ss-base-loading')

        within ".portlets .gws-survey" do
          click_on I18n.t("ss.links.more")
        end
      end

      within ".index" do
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)
        expect(page).to have_css(".list-item", text: item3.name)
        expect(page).to have_css(".list-item", text: item4.name)
        expect(page).to have_css(".list-item", text: item5.name)
        expect(page).to have_css(".list-item", text: item6.name)
        expect(page).to have_no_css(".list-item", text: item7.name)
        expect(page).to have_no_css(".list-item", text: item8.name)
        expect(page).to have_no_css(".list-item", text: item9.name)
        expect(page).to have_no_css(".list-item", text: item10.name)
        expect(page).to have_no_css(".list-item", text: item11.name)
        expect(page).to have_no_css(".list-item", text: item12.name)
      end
    end
  end
end
