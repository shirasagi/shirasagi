require 'spec_helper'

describe "gws_discussion_todos", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user1) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }
  let(:user2) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }
  let!(:forum) { create :gws_discussion_forum, member_ids: [ gws_user.id, user1.id, user2.id ] }
  let(:text) { "text-#{unique_id}" }
  let(:text2) { "text-#{unique_id}" }

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
    wait_for_ajax
    click_on I18n.t("ss.links.new")

    within "form#item-form" do
      fill_in "item[text]", with: text
      click_on I18n.t('ss.buttons.save')
    end
    wait_for_notice I18n.t('ss.notice.saved')

    expect(Gws::Schedule::Todo.without_deleted.count).to eq 1
    item = Gws::Schedule::Todo.without_deleted.first
    expect(item.name).to eq "[#{forum.name}]"
    expect(item.text).to eq text
    expect(item.member_ids).to include(*forum.member_ids)

    #
    # Read（カレンダー表示の確認）
    #
    visit gws_discussion_forums_path(site: site, mode: '-')
    click_on forum.name
    within ".addon-view.my-todo" do
      click_on I18n.t("gws/discussion.links.todo.index")
    end
    wait_for_ajax
    expect(page).to have_css('.fc-view a.fc-event-todo', text: item.name)
    # click_on item.name
    first('.fc-view a.fc-event-todo').click
    expect(current_path).to eq gws_discussion_forum_todo_path(site: site, mode: '-', forum_id: forum.id, id: item.id)

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
    expect(item.name).to eq "[#{forum.name}]"
    expect(item.text).to eq text2
    expect(item.member_ids).to include(*forum.member_ids)

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
  end
end
