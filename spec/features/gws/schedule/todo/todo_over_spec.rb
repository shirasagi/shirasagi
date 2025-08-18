require 'spec_helper'

describe "gws_schedule_todo_readables", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:now) { Time.zone.now.beginning_of_minute }

  let!(:item) { create :gws_schedule_todo, cur_site: site, cur_user: user, start_at: now - 1.day, end_at: now - 1.day }
  let!(:comment_text) { unique_id }
  let!(:achievement_rate) { 20 }

  before { login_gws_user }

  it do
    visit gws_schedule_todo_readables_path gws_site, "-"

    within ".list-items" do
      expect(page).to have_selector(".list-item", count: 1)
      expect(page).to have_css(".list-item .todo-over")
    end
    click_on item.name
    within "#addon-basic" do
      expect(page).to have_text item.name
      expect(page).to have_css(".todo-over")
    end

    # comment
    within "form#comment-form" do
      fill_in "item[text]", with: comment_text
      fill_in "item[achievement_rate]", with: achievement_rate
      click_on I18n.t('gws/schedule.buttons.comment')
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within "#addon-basic" do
      expect(page).to have_text item.name
      expect(page).to have_css(".todo-over")
    end

    # finish
    click_on I18n.t('gws/schedule/todo.links.finish')
    within "form#item-form" do
      click_on I18n.t('gws/schedule/todo.buttons.finish')
    end
    wait_for_notice I18n.t('ss.notice.saved')

    within "#addon-basic" do
      expect(page).to have_text item.name
      expect(page).to have_no_css(".todo-over")
    end

    click_on I18n.t('ss.links.back_to_index')
    within ".list-items" do
      expect(page).to have_selector(".list-item", count: 0)
    end

    select I18n.t("gws/schedule/todo.options.todo_state_filter.finished"), from: "s[todo_state]"
    within ".list-items" do
      expect(page).to have_selector(".list-item", count: 1)
      expect(page).to have_no_css(".list-item .todo-over")
    end
  end
end
