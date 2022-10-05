require 'spec_helper'

describe "gws_discussion_topics", type: :feature, dbscope: :example do
  context "reply", js: true do
    let!(:site) { gws_site }
    let!(:item) { create :gws_discussion_topic }
    let!(:index_path) { gws_discussion_forum_topics_path(mode: '-', site: site.id, forum_id: item.forum.id) }
    let!(:new_path) { new_gws_discussion_forum_topic_path(mode: '-', site: site.id, forum_id: item.forum.id) }
    let!(:show_path) { gws_discussion_forum_topic_path(mode: '-', site: site.id, forum_id: item.forum.id, id: item.id) }
    let!(:edit_path) { edit_gws_discussion_forum_topic_path(mode: '-', site: site.id, forum_id: item.forum.id, id: item.id) }
    let!(:delete_path) { delete_gws_discussion_forum_topic_path(mode: '-', site: site.id, forum_id: item.forum.id, id: item.id) }

    before { login_gws_user }

    it "#reply" do
      visit index_path
      #expect(page).to have_link I18n.t("gws/discussion.main_topic.name")

      click_on "コメントを投稿する"
      text = "text-#{unique_id}"
      within "form" do
        fill_in "item[text]", with: text
        click_button "返信する"
      end
      expect(page).to have_text(text)

      # edit
      within ".nav-menu" do
        click_on I18n.t('ss.links.edit')
      end
      text = "text-#{unique_id}"
      within "form#item-form" do
        fill_in "item[text]", with: text
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_text(text)

      # delete
      within ".nav-menu" do
        click_on I18n.t('ss.links.delete')
      end
      expect(page).to have_text(text)

      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end

      expect(page).to have_no_text(text)
    end
  end
end
