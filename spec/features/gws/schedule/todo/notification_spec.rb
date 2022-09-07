require 'spec_helper'

describe "gws_schedule_todo_readables", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:user1) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }
  let!(:user2) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }
  let(:name) { unique_id }
  let(:text) { unique_id }
  let(:name2) { unique_id }
  let(:text2) { unique_id }
  let(:achievement_rate) { rand(10..99) }
  let(:comment_text) { unique_id }
  let(:achievement_rate2) { rand(10..99) }
  let(:comment_text2) { unique_id }

  context "notification" do
    before { login_user user1 }

    it "operates to individual todo" do
      #
      # Create
      #
      visit gws_schedule_todo_readables_path gws_site, "-"

      click_on I18n.t("ss.links.new")
      within 'form#item-form' do
        fill_in 'item[name]', with: name
        fill_in 'item[text]', with: text

        select I18n.t("ss.options.state.enabled"), from: "item[notify_state]"

        within '.gws-addon-member' do
          wait_cbox_open do
            click_on I18n.t('ss.apis.users.index')
          end
        end
      end
      wait_for_cbox do
        expect(page).to have_content(user2.long_name)
        wait_cbox_close do
          click_on user2.long_name
        end
      end
      within 'form#item-form' do
        expect(page).to have_content(user2.name)
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Schedule::Todo.without_deleted.count).to eq 1
      todo = Gws::Schedule::Todo.without_deleted.first
      expect(todo.name).to eq name
      expect(todo.member_ids).to include(user1.id, user2.id)

      # notification sends only for user2
      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo.subject', name: todo.name)
        expect(message.url).to eq "/.g#{site.id}/schedule/todo/-/readables/#{todo.id}"
        expect(message.member_ids).to eq [ user2.id ]
      end

      #
      # Update
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on name
      click_on I18n.t("ss.links.edit")
      within 'form#item-form' do
        fill_in 'item[name]', with: name2
        fill_in 'item[text]', with: text2

        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Schedule::Todo.without_deleted.count).to eq 1
      todo.reload
      expect(todo.name).to eq name2

      expect(SS::Notification.count).to eq 2
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo.subject', name: todo.name)
        expect(message.url).to eq "/.g#{site.id}/schedule/todo/-/readables/#{todo.id}"
        expect(message.member_ids).to eq [ user2.id ]
      end

      #
      # Finish
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on name2
      click_on I18n.t('gws/schedule/todo.links.finish')
      within "form" do
        click_on I18n.t('gws/schedule/todo.buttons.finish')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Schedule::Todo.without_deleted.count).to eq 1
      todo.reload
      expect(todo.todo_state).to eq "finished"
      expect(todo.comments.count).to eq 1

      expect(SS::Notification.count).to eq 3
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo/finish.subject', name: todo.name)
        expect(message.url).to eq "/.g#{site.id}/schedule/todo/-/readables/#{todo.id}"
        expect(message.member_ids).to eq [ user2.id ]
      end

      #
      # Revert
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      select I18n.t("gws/schedule/todo.options.todo_state_filter.finished"), from: "s[todo_state]"
      click_on name2
      click_on I18n.t('gws/schedule/todo.links.revert')
      within "form" do
        click_on I18n.t('gws/schedule/todo.buttons.revert')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Schedule::Todo.without_deleted.count).to eq 1
      todo.reload
      expect(todo.todo_state).to eq "unfinished"
      expect(todo.comments.count).to eq 2

      expect(SS::Notification.count).to eq 4
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo/revert.subject', name: todo.name)
        expect(message.url).to eq "/.g#{site.id}/schedule/todo/-/readables/#{todo.id}"
        expect(message.member_ids).to eq [ user2.id ]
      end

      #
      # Create Comment
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on name2
      within "form#comment-form" do
        fill_in "item[achievement_rate]", with: achievement_rate
        fill_in "item[text]", with: comment_text
        click_on I18n.t('gws/schedule.buttons.comment')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      todo.reload
      expect(todo.achievement_rate).to eq achievement_rate
      expect(todo.comments.count).to eq 3

      expect(SS::Notification.count).to eq 5
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo_comment.subject', name: todo.name)
        expect(message.url).to eq "/.g#{site.id}/schedule/todo/-/readables/#{todo.id}"
        expect(message.member_ids).to eq [ user2.id ]
      end

      #
      # Edit Comment
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on name2
      within "#addon-gws-agents-addons-schedule-todo-comment_post" do
        within "#comment-#{todo.comments.order_by(created: -1).first.id}" do
          expect(page).to have_content(comment_text)
          wait_cbox_open do
            click_on I18n.t("ss.buttons.edit")
          end
        end
      end
      wait_for_cbox do
        expect(page).to have_content(comment_text)

        fill_in "item[achievement_rate]", with: achievement_rate2
        fill_in "item[text]", with: comment_text2

        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      todo.reload
      expect(todo.achievement_rate).to eq achievement_rate2

      expect(SS::Notification.count).to eq 6
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo_comment.subject', name: todo.name)
        expect(message.url).to eq "/.g#{site.id}/schedule/todo/-/readables/#{todo.id}"
        expect(message.member_ids).to eq [ user2.id ]
      end

      #
      # Delete Comment
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on name2
      within "#addon-gws-agents-addons-schedule-todo-comment_post" do
        within "#comment-#{todo.comments.order_by(created: -1).first.id}" do
          expect(page).to have_content(comment_text2)
          wait_cbox_open do
            click_on I18n.t("ss.buttons.delete")
          end
        end
      end
      wait_for_cbox do
        expect(page).to have_content(comment_text2)
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      # confirm that no notifications are sent
      expect(SS::Notification.count).to eq 7
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo_comment/destroy.subject', name: todo.name)
        expect(message.url).to eq "/.g#{site.id}/schedule/todo/-/readables/#{todo.id}"
        expect(message.member_ids).to eq [ user2.id ]
      end

      #
      # Delete (soft delete)
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on name2
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within 'form' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect(Gws::Schedule::Todo.without_deleted.count).to eq 0
      expect(Gws::Schedule::Todo.only_deleted.count).to eq 1
      todo.reload
      expect(todo.deleted).to be_present

      expect(SS::Notification.count).to eq 8
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo/destroy.subject', name: todo.name)
        expect(message.url).to eq ""
        expect(message.member_ids).to eq [ user2.id ]
      end

      #
      # Delete (hard delete)
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on I18n.t('gws/schedule.navi.trash')
      click_on name2
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within 'form' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect(Gws::Schedule::Todo.without_deleted.count).to eq 0
      expect(Gws::Schedule::Todo.only_deleted.count).to eq 0

      # confirm that no notifications are sent
      expect(SS::Notification.count).to eq 8
    end

    it "operates to batch of todos" do
      #
      # Create
      #
      visit gws_schedule_todo_readables_path gws_site, "-"

      click_on I18n.t("ss.links.new")
      within 'form#item-form' do
        fill_in 'item[name]', with: name
        fill_in 'item[text]', with: text

        select I18n.t("ss.options.state.enabled"), from: "item[notify_state]"

        within '.gws-addon-member' do
          wait_cbox_open do
            click_on I18n.t('ss.apis.users.index')
          end
        end
      end
      wait_for_cbox do
        expect(page).to have_content(user2.long_name)
        wait_cbox_close do
          click_on user2.long_name
        end
      end
      within 'form#item-form' do
        expect(page).to have_content(user2.name)
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Schedule::Todo.without_deleted.count).to eq 1
      todo = Gws::Schedule::Todo.without_deleted.first
      expect(todo.name).to eq name
      expect(todo.member_ids).to include(user1.id, user2.id)

      # notification sends only for user2
      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo.subject', name: todo.name)
        expect(message.url).to eq "/.g#{site.id}/schedule/todo/-/readables/#{todo.id}"
        expect(message.member_ids).to eq [ user2.id ]
      end

      #
      # Finish All
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      find('.list-head label.check input').set(true)
      page.accept_confirm do
        find('.finish-all').click
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      todo.reload
      expect(todo.todo_state).to eq "finished"

      expect(SS::Notification.count).to eq 2
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo/finish.subject', name: todo.name)
        expect(message.url).to eq "/.g#{site.id}/schedule/todo/-/readables/#{todo.id}"
        expect(message.member_ids).to eq [ user2.id ]
      end

      #
      # Revert All
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      select I18n.t("gws/schedule/todo.options.todo_state_filter.finished"), from: "s[todo_state]"
      find('.list-head label.check input').set(true)
      page.accept_confirm do
        find('.revert-all').click
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      todo.reload
      expect(todo.todo_state).to eq "unfinished"

      expect(SS::Notification.count).to eq 3
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo/revert.subject', name: todo.name)
        expect(message.url).to eq "/.g#{site.id}/schedule/todo/-/readables/#{todo.id}"
        expect(message.member_ids).to eq [ user2.id ]
      end

      #
      # Delete All (soft delete)
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      find('.list-head label.check input').set(true)
      page.accept_confirm do
        find('.disable-all').click
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      todo.reload
      expect(todo.deleted).to be_present

      expect(SS::Notification.count).to eq 4
      SS::Notification.order_by(created: -1).first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo/destroy.subject', name: todo.name)
        expect(message.url).to eq ""
        expect(message.member_ids).to eq [ user2.id ]
      end

      #
      # Delete All (hard delete)
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on I18n.t('gws/schedule.navi.trash')
      find('.list-head label.check input').set(true)
      page.accept_confirm do
        find('.destroy-all').click
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect(Gws::Schedule::Todo.without_deleted.count).to eq 0
      expect(Gws::Schedule::Todo.only_deleted.count).to eq 0

      # confirm that no notifications are sent
      expect(SS::Notification.count).to eq 4
    end
  end

  context "undo delete notification" do
    let!(:todo) do
      create(
        :gws_schedule_todo, cur_site: site, cur_user: user1, notify_state: "enabled",
        member_ids: [ user1.id, user2.id ], deleted: Time.zone.now
      )
    end

    before { login_user user1 }

    it do
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on I18n.t('gws/schedule.navi.trash')
      click_on todo.name
      click_on I18n.t("ss.links.restore")
      within "form" do
        click_on I18n.t("ss.buttons.restore")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.restored'))

      expect(SS::Notification.count).to eq 1
      message = SS::Notification.first
      expect(message.subject).to eq I18n.t('gws_notification.gws/schedule/todo/undo_delete.subject', name: todo.name)
      expect(message.url).to eq "/.g#{site.id}/schedule/todo/-/readables/#{todo.id}"
      expect(message.member_ids).to eq [ user2.id ]
    end
  end
end
