require 'spec_helper'

describe "gws_discussion_topics", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:role) { create :gws_role_admin, cur_site: site }
  let!(:user1) { create :gws_user, gws_role_ids: [role.id] }
  let!(:user2) { create :gws_user, gws_role_ids: [role.id] }

  let!(:item) { create :gws_discussion_topic }
  let!(:forums_path) { gws_discussion_forums_path(mode: '-', site: site.id) }

  before do
    forum = item.forum
    forum.member_ids = [user1.id, user2.id]
    forum.update
  end

  it "bookmark from portal" do
    login_user(user1)

    visit forums_path
    click_on item.forum.name
    within "#comment-#{item.id}" do
      expect(page).to have_no_css(".bookmark-comment .active")
      expect(page).to have_css(".bookmark-comment .inactive")
      first(".bookmark-comment").click
    end

    visit forums_path
    click_on item.forum.name
    within "#comment-#{item.id}" do
      expect(page).to have_css(".bookmark-comment .active")
      expect(page).to have_no_css(".bookmark-comment .inactive")
    end

    within ".gws-discussion-navi .bookmarks" do
      expect(page).to have_text(item.summary_text)
      click_on item.name
    end
    expect(page).to have_css(".gws-discussion")

    login_user(user2)

    visit forums_path
    click_on item.forum.name
    within "#comment-#{item.id}" do
      expect(page).to have_no_css(".bookmark-comment .active")
      expect(page).to have_css(".bookmark-comment .inactive")
      first(".bookmark-comment").click
    end

    visit forums_path
    click_on item.forum.name
    within "#comment-#{item.id}" do
      expect(page).to have_css(".bookmark-comment .active")
      expect(page).to have_no_css(".bookmark-comment .inactive")
    end

    within ".gws-discussion-navi .bookmarks" do
      expect(page).to have_text(item.summary_text)
      click_on item.name
    end
    expect(page).to have_css(".gws-discussion")
  end

  it "bookmark from comments" do
    login_user(user1)

    visit forums_path
    click_on item.forum.name
    within ".gws-discussion-thread" do
      click_on item.name
    end
    within "#comment-#{item.id}" do
      expect(page).to have_no_css(".bookmark-comment .active")
      expect(page).to have_css(".bookmark-comment .inactive")
      first(".bookmark-comment").click
    end

    visit forums_path
    click_on item.forum.name
    within "#comment-#{item.id}" do
      expect(page).to have_css(".bookmark-comment .active")
      expect(page).to have_no_css(".bookmark-comment .inactive")
    end
    within ".gws-discussion-navi .bookmarks" do
      expect(page).to have_text(item.summary_text)
      click_on item.name
    end
    expect(page).to have_css(".gws-discussion")

    login_user(user2)

    visit forums_path
    click_on item.forum.name
    within ".gws-discussion-thread" do
      click_on item.name
    end
    within "#comment-#{item.id}" do
      expect(page).to have_no_css(".bookmark-comment .active")
      expect(page).to have_css(".bookmark-comment .inactive")
      first(".bookmark-comment").click
    end

    visit forums_path
    click_on item.forum.name
    within "#comment-#{item.id}" do
      expect(page).to have_css(".bookmark-comment .active")
      expect(page).to have_no_css(".bookmark-comment .inactive")
    end
    within ".gws-discussion-navi .bookmarks" do
      expect(page).to have_text(item.summary_text)
      click_on item.name
    end
    expect(page).to have_css(".gws-discussion")
  end
end
