require 'spec_helper'

describe "gws_schedule_todo_readables", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:item) { create :gws_schedule_todo, cur_site: site, cur_user: user }

  before { login_gws_user }

  describe "#finish" do
    it do
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on item.name
      click_on I18n.t('gws/schedule/todo.links.finish')

      within "form#item-form" do
        click_on I18n.t('gws/schedule/todo.buttons.finish')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.todo_state).to eq "finished"
      expect(item.achievement_rate).to eq 100

      expect(Gws::Schedule::TodoComment.count).to eq 1
      Gws::Schedule::TodoComment.first.tap do |comment|
        expect(comment.text).to be_blank
        expect(comment.achievement_rate).to eq 100
      end
    end
  end

  describe "#revert" do
    before do
      item.todo_state = "finished"
      item.achievement_rate = 100
      item.save!
    end

    it do
      visit gws_schedule_todo_readables_path gws_site, "-"
      select I18n.t("gws/schedule/todo.options.todo_state_filter.finished"), from: "s[todo_state]"

      click_on item.name
      click_on I18n.t('gws/schedule/todo.links.revert')

      within "form#item-form" do
        click_on I18n.t('gws/schedule/todo.buttons.revert')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.todo_state).to eq "unfinished"
      expect(item.achievement_rate).to eq 0

      expect(Gws::Schedule::TodoComment.count).to eq 1
      Gws::Schedule::TodoComment.first.tap do |comment|
        expect(comment.text).to be_blank
        expect(comment.achievement_rate).to eq 0
      end
    end
  end

  describe "#finish_all" do
    it do
      visit gws_schedule_todo_readables_path gws_site, "-"
      wait_event_to_fire("ss:checked-all-list-items") { find('.list-head label.check input').set(true) }
      page.accept_confirm do
        find('.finish-all').click
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.todo_state).to eq "finished"
      expect(item.achievement_rate).to eq 100

      expect(Gws::Schedule::TodoComment.count).to eq 1
      Gws::Schedule::TodoComment.first.tap do |comment|
        expect(comment.text).to be_blank
        expect(comment.achievement_rate).to eq 100
      end
    end
  end

  describe "#revert_all" do
    before do
      item.todo_state = "finished"
      item.achievement_rate = 100
      item.save!
    end

    it do
      visit gws_schedule_todo_readables_path gws_site, "-"
      select I18n.t("gws/schedule/todo.options.todo_state_filter.finished"), from: "s[todo_state]"

      wait_event_to_fire("ss:checked-all-list-items") { find('.list-head label.check input').set(true) }
      page.accept_confirm do
        find('.revert-all').click
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.todo_state).to eq "unfinished"
      expect(item.achievement_rate).to eq 0

      expect(Gws::Schedule::TodoComment.count).to eq 1
      Gws::Schedule::TodoComment.first.tap do |comment|
        expect(comment.text).to be_blank
        expect(comment.achievement_rate).to eq 0
      end
    end
  end
end
