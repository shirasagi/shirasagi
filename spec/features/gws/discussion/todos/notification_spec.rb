require 'spec_helper'

describe "gws_discussion_todos", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let(:site) { gws_site }
    let(:user1) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }
    let(:user2) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }
    let!(:forum) { create :gws_discussion_forum, member_ids: [ gws_user.id, user1.id, user2.id ] }
    let(:text) { "text-#{unique_id}" }
    let(:text2) { "text-#{unique_id}" }
    let(:achievement_rate) { rand(10..99) }
    let(:comment_text) { unique_id }
    let(:achievement_rate2) { rand(10..99) }
    let(:comment_text2) { unique_id }

    before { login_gws_user }

    it do
      #
      # Create
      #
      visit gws_discussion_forums_path(site: site, mode: '-')
      click_on forum.name
      within ".addon-view.my-todo" do
        click_on I18n.t("gws/discussion.links.todo.index")
      end
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[text]", with: text
        select I18n.t("ss.options.state.enabled"), from: "item[notify_state]"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Schedule::Todo.without_deleted.count).to eq 1
      item = Gws::Schedule::Todo.without_deleted.first
      expect(item.name).to eq "[#{forum.name}]"
      expect(item.text).to eq text
      expect(item.member_ids).to include(*forum.member_ids)

      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo.subject', name: item.name)
        expect(message.url).to eq "/.g#{site.id}/discussion/-/forums/#{forum.id}/todos/#{item.id}"
        expect(message.member_ids).to include(user1.id, user2.id)
      end

      #
      # Update
      #
      visit gws_discussion_forums_path(site: site, mode: '-')
      click_on forum.name
      within ".addon-view.my-todo" do
        click_on item.name
      end
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[text]", with: text2
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.text).to eq text2

      expect(SS::Notification.count).to eq 2
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo.subject', name: item.name)
        expect(message.url).to eq "/.g#{site.id}/discussion/-/forums/#{forum.id}/todos/#{item.id}"
        expect(message.member_ids).to include(user1.id, user2.id)
      end

      #
      # Finish
      #
      visit gws_discussion_forums_path(site: site, mode: '-')
      click_on forum.name
      within ".addon-view.my-todo" do
        click_on item.name
      end
      click_on I18n.t('gws/schedule/todo.links.finish')
      within "form#item-form" do
        click_on I18n.t('gws/schedule/todo.buttons.finish')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.todo_state).to eq "finished"
      expect(item.comments.count).to eq 1

      expect(SS::Notification.count).to eq 3
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo/finish.subject', name: item.name)
        expect(message.url).to eq "/.g#{site.id}/discussion/-/forums/#{forum.id}/todos/#{item.id}"
        expect(message.member_ids).to include(user1.id, user2.id)
      end

      #
      # Revert
      # 電子会議室の場合、未完に戻すには、カレンダー表示から辿る必要がある。
      #
      visit gws_discussion_forums_path(site: site, mode: '-')
      click_on forum.name
      within ".addon-view.my-todo" do
        # 完了した ToDo は一覧に表示されていないはず
        expect(page).to have_no_content(item.name)
        click_on I18n.t("gws/discussion.links.todo.index")
      end
      # click_on item.name
      first('.fc-view a.fc-event-todo').click
      click_on I18n.t('gws/schedule/todo.links.revert')
      within "form#item-form" do
        click_on I18n.t('gws/schedule/todo.buttons.revert')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Schedule::Todo.without_deleted.count).to eq 1
      item.reload
      expect(item.todo_state).to eq "unfinished"
      expect(item.comments.count).to eq 2

      expect(SS::Notification.count).to eq 4
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo/revert.subject', name: item.name)
        expect(message.url).to eq "/.g#{site.id}/discussion/-/forums/#{forum.id}/todos/#{item.id}"
        expect(message.member_ids).to include(user1.id, user2.id)
      end

      #
      # Create Comment
      #
      visit gws_discussion_forums_path(site: site, mode: '-')
      click_on forum.name
      within ".addon-view.my-todo" do
        click_on item.name
      end
      within "form#comment-form" do
        fill_in "item[achievement_rate]", with: achievement_rate
        fill_in "item[text]", with: comment_text
        click_on I18n.t('gws/schedule.buttons.comment')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.achievement_rate).to eq achievement_rate
      expect(item.todo_state).to eq "progressing"
      expect(item.comments.count).to eq 3

      expect(SS::Notification.count).to eq 5
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo_comment.subject', name: item.name)
        expect(message.url).to eq "/.g#{site.id}/discussion/-/forums/#{forum.id}/todos/#{item.id}"
        expect(message.member_ids).to include(user1.id, user2.id)
      end

      #
      # Edit Comment
      #
      visit gws_discussion_forums_path(site: site, mode: '-')
      click_on forum.name
      within ".addon-view.my-todo" do
        click_on item.name
      end
      within "#addon-gws-agents-addons-schedule-todo-comment_post" do
        within "#comment-#{item.comments.order_by(created: -1).first.id}" do
          expect(page).to have_content(comment_text)
          wait_cbox_open { click_on I18n.t("ss.buttons.edit") }
        end
      end
      wait_for_cbox do
        expect(page).to have_content(comment_text)

        fill_in "item[achievement_rate]", with: achievement_rate2
        fill_in "item[text]", with: comment_text2
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.achievement_rate).to eq achievement_rate2
      expect(item.todo_state).to eq "progressing"

      expect(SS::Notification.count).to eq 6
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo_comment.subject', name: item.name)
        expect(message.url).to eq "/.g#{site.id}/discussion/-/forums/#{forum.id}/todos/#{item.id}"
        expect(message.member_ids).to include(user1.id, user2.id)
      end

      #
      # Delete Comment
      #
      visit gws_discussion_forums_path(site: site, mode: '-')
      click_on forum.name
      within ".addon-view.my-todo" do
        click_on item.name
      end
      within "#addon-gws-agents-addons-schedule-todo-comment_post" do
        within "#comment-#{item.comments.order_by(created: -1).first.id}" do
          expect(page).to have_content(comment_text2)
          wait_cbox_open { click_on I18n.t("ss.buttons.delete") }
        end
      end
      wait_for_cbox do
        expect(page).to have_content(comment_text2)
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      item.reload
      expect(item.achievement_rate).to eq 0
      expect(item.todo_state).to eq "unfinished"

      # confirm that no notifications are sent
      expect(SS::Notification.count).to eq 7
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo_comment/destroy.subject', name: item.name)
        expect(message.url).to eq "/.g#{site.id}/discussion/-/forums/#{forum.id}/todos/#{item.id}"
        expect(message.member_ids).to include(user1.id, user2.id)
      end

      #
      # Delete
      #
      visit gws_discussion_forums_path(site: site, mode: '-')
      click_on forum.name
      within ".addon-view.my-todo" do
        click_on item.name
      end
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect(Gws::Schedule::Todo.without_deleted.count).to eq 0
      expect(Gws::Schedule::Todo.only_deleted.count).to eq 1

      expect(SS::Notification.count).to eq 8
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo/destroy.subject', name: item.name)
        expect(message.url).to eq ""
        expect(message.member_ids).to include(user1.id, user2.id)
      end
    end
  end
end
