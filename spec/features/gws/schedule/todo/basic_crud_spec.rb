require 'spec_helper'

describe "gws_schedule_todo_readables", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:user1) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }
  let!(:user2) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }
  let(:name) { unique_id }
  let(:text) { unique_id }
  let(:name2) { unique_id }
  let(:text2) { unique_id }

  context "basic crud" do
    before { login_user user1 }

    it do
      #
      # Create
      #
      visit gws_schedule_todo_readables_path gws_site, "-"

      click_on I18n.t("ss.links.new")
      within 'form#item-form' do
        fill_in 'item[name]', with: name
        fill_in 'item[text]', with: text

        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Schedule::Todo.without_deleted.count).to eq 1
      Gws::Schedule::Todo.without_deleted.first.tap do |todo|
        expect(todo.name).to eq name
        expect(todo.text).to eq text
        expect(todo.todo_state).to eq "unfinished"
        expect(todo.achievement_rate).to be_nil
        expect(todo.member_ids).to include user1.id
        expect(todo.readable_group_ids).to include user1.group_ids.first
        expect(todo.user_ids).to include user1.id
      end

      # 自分宛ての ToDo では、一切の通知は送られない
      expect(SS::Notification.count).to eq 0

      #
      # Read
      #
      visit gws_schedule_todo_readables_path gws_site, "-"
      click_on name
      expect(page).to have_content(name)
      expect(page).to have_content(text)

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
      Gws::Schedule::Todo.without_deleted.first.tap do |todo|
        expect(todo.name).to eq name2
        expect(todo.text).to eq text2
        expect(todo.todo_state).to eq "unfinished"
        expect(todo.achievement_rate).to be_nil
        expect(todo.member_ids).to include user1.id
        expect(todo.readable_group_ids).to include user1.group_ids.first
        expect(todo.user_ids).to include user1.id
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
      Gws::Schedule::Todo.only_deleted.first.tap do |todo|
        expect(todo.name).to eq name2
        expect(todo.text).to eq text2
      end

      # 自分宛ての ToDo では、一切の通知は送られない
      expect(SS::Notification.count).to eq 0
    end
  end
end
