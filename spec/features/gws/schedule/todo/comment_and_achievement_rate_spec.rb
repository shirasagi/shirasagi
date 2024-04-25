require 'spec_helper'

describe "gws_schedule_todo_readables", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:item) { create :gws_schedule_todo }
  let(:achievement_rate1) { rand(10..20) }
  let(:comment_text1) { unique_id }
  let(:achievement_rate2) { rand(30..40) }
  let(:comment_text2) { unique_id }
  let(:achievement_rate3) { rand(50..60) }
  let(:comment_text3) { unique_id }

  before { login_gws_user }

  describe "basic crud" do
    it do
      #
      # Create
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on item.name
      within "form#comment-form" do
        fill_in "item[text]", with: comment_text1
        fill_in "item[achievement_rate]", with: achievement_rate1
        click_on I18n.t('gws/schedule.buttons.comment')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.achievement_rate).to eq achievement_rate1
      expect(item.comments.count).to eq 1
      item.comments.order_by(created: -1).first.tap do |comment|
        expect(comment.achievement_rate).to eq achievement_rate1
        expect(comment.text).to eq comment_text1
      end

      #
      # Update
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on item.name
      within "#addon-gws-agents-addons-schedule-todo-comment_post" do
        within "#comment-#{item.comments.order_by(created: -1).first.id}" do
          expect(page).to have_content(comment_text1)
          wait_cbox_open { click_on I18n.t("ss.buttons.edit") }
        end
      end
      within_cbox do
        expect(page).to have_content(comment_text1)

        fill_in "item[achievement_rate]", with: achievement_rate2
        fill_in "item[text]", with: comment_text2

        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.achievement_rate).to eq achievement_rate2
      expect(item.comments.count).to eq 1
      item.comments.order_by(created: -1).first.tap do |comment|
        expect(comment.achievement_rate).to eq achievement_rate2
        expect(comment.text).to eq comment_text2
      end

      #
      # Delete
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on item.name
      within "#addon-gws-agents-addons-schedule-todo-comment_post" do
        within "#comment-#{item.comments.order_by(created: -1).first.id}" do
          expect(page).to have_content(comment_text2)
          wait_cbox_open { click_on I18n.t("ss.buttons.delete") }
        end
      end
      within_cbox do
        expect(page).to have_content(comment_text2)
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      item.reload
      expect(item.achievement_rate).to eq 0
      expect(item.comments.count).to eq 0
    end
  end

  describe "advanced crud" do
    let!(:comment1) do
      Gws::Schedule::TodoComment.create!(cur_site: site, cur_todo: item, text: unique_id, achievement_rate: rand(10..20))
    end
    let!(:comment1_half) do
      Gws::Schedule::TodoComment.create!(cur_site: site, cur_todo: item, text: unique_id)
    end
    let!(:comment2) do
      Gws::Schedule::TodoComment.create!(cur_site: site, cur_todo: item, text: unique_id, achievement_rate: rand(30..40))
    end

    before do
      item.achievement_rate = comment2.achievement_rate
      item.save!
    end

    it "updates first comment achievement_rate" do
      #
      # Update first comment, this operation doesn't affect item.achievement_rate
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on item.name
      within "#addon-gws-agents-addons-schedule-todo-comment_post" do
        within "#comment-#{comment1.id}" do
          expect(page).to have_content(comment1.text)
          wait_cbox_open { click_on I18n.t("ss.buttons.edit") }
        end
      end
      within_cbox do
        expect(page).to have_content(comment1.text)

        fill_in "item[achievement_rate]", with: comment1.achievement_rate + 1

        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.achievement_rate).to eq comment2.achievement_rate
    end

    it "deletes comment2" do
      #
      # Delete comment2, and then item.achievement_rate is back to comment1.achievement_rate
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on item.name
      within "#addon-gws-agents-addons-schedule-todo-comment_post" do
        within "#comment-#{comment2.id}" do
          expect(page).to have_content(comment2.text)
          wait_cbox_open { click_on I18n.t("ss.buttons.delete") }
        end
      end
      within_cbox do
        expect(page).to have_content(comment2.text)
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      item.reload
      expect(item.achievement_rate).to eq comment1.achievement_rate
    end

    it "adds new achivement_rate that is lesss than last achievement_rate" do
      #
      # Add new achivement_rate that is lesss than last achievement_rate,
      # and then item.achievement_rate is updated with new achievement_rate.
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on item.name
      within "form#comment-form" do
        fill_in "item[achievement_rate]", with: comment2.achievement_rate - 5
        click_on I18n.t('gws/schedule.buttons.comment')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.achievement_rate).to eq comment2.achievement_rate - 5
    end

    it "adds comment without achivement_rate" do
      #
      # Add new comment without achivement_rate,
      # and then item.achivement_rate holds comment2.achivement_rate
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on item.name
      within "form#comment-form" do
        fill_in "item[text]", with: unique_id
        click_on I18n.t('gws/schedule.buttons.comment')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.achievement_rate).to eq comment2.achievement_rate
    end
  end
end
