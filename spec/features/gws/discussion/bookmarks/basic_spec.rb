require 'spec_helper'

describe "gws_discussion_topics", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:role) { create :gws_role_admin, cur_site: site }
  let!(:user1) { create :gws_user, gws_role_ids: [role.id] }
  let!(:user2) { create :gws_user, gws_role_ids: [role.id] }

  let!(:forum) { create :gws_discussion_forum, member_ids: [user1.id, user2.id] }
  let!(:topic) { create :gws_discussion_topic, forum: forum, parent: forum }
  let!(:index_path) { gws_discussion_forums_path(mode: '-', site: site) }

  it "bookmark from portal" do
    login_user(user1)

    visit index_path
    click_on forum.name
    within "#comment-#{topic.id}" do
      expect(page).to have_no_css(".bookmark-comment .active")
      expect(page).to have_css(".bookmark-comment .inactive")
      first(".bookmark-comment").click
    end

    visit index_path
    click_on forum.name
    within "#comment-#{topic.id}" do
      expect(page).to have_css(".bookmark-comment .active")
      expect(page).to have_no_css(".bookmark-comment .inactive")
    end

    within ".gws-discussion-navi .bookmarks" do
      expect(page).to have_text(topic.summary_text)
      click_on topic.name
    end
    expect(page).to have_css(".gws-discussion")

    login_user(user2)

    visit index_path
    click_on forum.name
    within "#comment-#{topic.id}" do
      expect(page).to have_no_css(".bookmark-comment .active")
      expect(page).to have_css(".bookmark-comment .inactive")
      first(".bookmark-comment").click
    end

    visit index_path
    click_on forum.name
    within "#comment-#{topic.id}" do
      expect(page).to have_css(".bookmark-comment .active")
      expect(page).to have_no_css(".bookmark-comment .inactive")
    end

    within ".gws-discussion-navi .bookmarks" do
      expect(page).to have_text(topic.summary_text)
      click_on topic.name
    end
    expect(page).to have_css(".gws-discussion")
  end

  it "bookmark from comments" do
    login_user(user1)

    visit index_path
    click_on forum.name
    within ".gws-discussion-thread" do
      click_on topic.name
    end
    within "#comment-#{topic.id}" do
      expect(page).to have_no_css(".bookmark-comment .active")
      expect(page).to have_css(".bookmark-comment .inactive")
      first(".bookmark-comment").click
    end

    visit index_path
    click_on forum.name
    within "#comment-#{topic.id}" do
      expect(page).to have_css(".bookmark-comment .active")
      expect(page).to have_no_css(".bookmark-comment .inactive")
    end
    within ".gws-discussion-navi .bookmarks" do
      expect(page).to have_text(topic.summary_text)
      click_on topic.name
    end
    expect(page).to have_css(".gws-discussion")

    login_user(user2)

    visit index_path
    click_on forum.name
    within ".gws-discussion-thread" do
      click_on topic.name
    end
    within "#comment-#{topic.id}" do
      expect(page).to have_no_css(".bookmark-comment .active")
      expect(page).to have_css(".bookmark-comment .inactive")
      first(".bookmark-comment").click
    end

    visit index_path
    click_on forum.name
    within "#comment-#{topic.id}" do
      expect(page).to have_css(".bookmark-comment .active")
      expect(page).to have_no_css(".bookmark-comment .inactive")
    end
    within ".gws-discussion-navi .bookmarks" do
      expect(page).to have_text(topic.summary_text)
      click_on topic.name
    end
    expect(page).to have_css(".gws-discussion")
  end
end
