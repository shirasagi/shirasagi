require 'spec_helper'

describe "gws_discussion_topics", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:forum) { create :gws_discussion_forum }
  let!(:topic) { create :gws_discussion_topic, forum: forum, parent: forum }

  let!(:index_path) { gws_discussion_forum_topics_path(mode: '-', site: site, forum_id: forum) }
  let!(:new_path) { new_gws_discussion_forum_topic_path(mode: '-', site: site, forum_id: forum) }
  let!(:show_path) { gws_discussion_forum_topic_path(mode: '-', site: site, forum_id: forum, id: topic) }
  let!(:edit_path) { edit_gws_discussion_forum_topic_path(mode: '-', site: site, forum_id: forum, id: topic) }
  let!(:delete_path) { delete_gws_discussion_forum_topic_path(mode: '-', site: site, forum_id: forum, id: topic) }

  before { login_gws_user }

  it "#reply" do
    visit index_path
    within ".gws-discussion-topic" do
      expect(page).to have_text(forum.name)
    end

    click_on I18n.t("gws/discussion.links.topic.reply")
    text = "text-#{unique_id}"
    within "form.reply" do
      fill_in "item[text]", with: text
      click_button I18n.t("ss.links.reply")
    end
    expect(page).to have_text(text)

    # edit
    within "#topic-#{topic.id}" do
      click_on I18n.t('ss.links.edit')
    end
    text = "text-#{unique_id}"
    within "form#item-form" do
      fill_in "item[text]", with: text
      click_button I18n.t('ss.buttons.save')
    end
    expect(page).to have_text(text)

    # delete
    within "#topic-#{topic.id}" do
      click_on I18n.t('ss.links.delete')
    end
    expect(page).to have_text(text)

    within "form#item-form" do
      click_button I18n.t('ss.buttons.delete')
    end

    expect(page).to have_no_text(text)
  end
end
