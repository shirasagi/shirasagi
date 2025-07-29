require 'spec_helper'

describe "gws_workload_works", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:show_path) { gws_workload_work_path site, item }

  let(:item) { create :gws_workload_work }
  let(:comment) { create :gws_workload_work_comment, work: item }
  let(:text) { unique_id }
  let(:commented_at) { Time.zone.now.advance(months: 1) }

  context "with auth" do
    before { login_gws_user }

    it "#show" do
      visit show_path

      # comment 30% 2:00
      within "#addon-gws-agents-addons-workload-comment_post" do
        within "#comment-form" do
          fill_in "item[achievement_rate]", with: "30"
          select "2", from: "item[in_worktime_hours]"
          select "0", from: "item[in_worktime_minutes]"
          fill_in "item[text]", with: unique_id
          click_on I18n.t('gws/workload.buttons.comment')
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within "#addon-gws-agents-addons-workload-comment_post" do
        within ".comment.total" do
          expect(page).to have_css(".achievement-rate", text: "30%")
          expect(page).to have_css(".worktime-minutes", text: "2:00")
        end
      end

      # comment 40% 1:15
      within "#addon-gws-agents-addons-workload-comment_post" do
        within "#comment-form" do
          fill_in "item[achievement_rate]", with: "40"
          select "1", from: "item[in_worktime_hours]"
          select "15", from: "item[in_worktime_minutes]"
          fill_in "item[text]", with: unique_id
          click_on I18n.t('gws/workload.buttons.comment')
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within "#addon-gws-agents-addons-workload-comment_post" do
        within ".comment.total" do
          expect(page).to have_css(".achievement-rate", text: "40%")
          expect(page).to have_css(".worktime-minutes", text: "3:15")
        end
      end

      # comment text only
      within "#addon-gws-agents-addons-workload-comment_post" do
        within "#comment-form" do
          fill_in "item[text]", with: unique_id
          click_on I18n.t('gws/workload.buttons.comment')
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within "#addon-gws-agents-addons-workload-comment_post" do
        within ".comment.total" do
          expect(page).to have_css(".achievement-rate", text: "40%")
          expect(page).to have_css(".worktime-minutes", text: "3:15")
        end
      end
    end

    it "#show" do
      comment
      visit show_path
      within ".gws-comment-post" do
        within "#comment-#{comment.id}" do
          click_on I18n.t("ss.buttons.edit")
        end
      end
      within_cbox do
        fill_in "item[text]", with: text
        fill_in "item[achievement_rate]", with: "20"
        select "1", from: "item[in_worktime_hours]"
        select "30", from: "item[in_worktime_minutes]"
        fill_in "item[commented_at]", with: I18n.l(commented_at, format: :picker)
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within ".gws-comment-post" do
        within "#comment-#{comment.id}" do
          expect(page).to have_css(".achievement-rate", text: "20%")
          expect(page).to have_css(".worktime-minutes", text: "1:30")
          expect(page).to have_css(".commented-at", text: I18n.l(commented_at))
        end
      end
    end

    it "#show" do
      comment
      visit show_path
      within ".gws-comment-post" do
        within "#comment-#{comment.id}" do
          click_on I18n.t("ss.buttons.delete")
        end
      end
      within_cbox do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      within ".gws-comment-post" do
        expect(page).to have_no_css("#comment-#{comment.id}")
      end
    end
  end
end
