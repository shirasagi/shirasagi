require 'spec_helper'

describe "gws_discussion_comments", type: :feature, dbscope: :example do
  context "reply", js: true do
    let!(:site) { gws_site }
    let!(:item) { create :gws_discussion_topic }
    let!(:index_path) do
      gws_discussion_forum_topic_comments_path(mode: '-', site: site.id, forum_id: item.forum.id, topic_id: item.id)
    end

    before { login_gws_user }

    it "#reply" do
      visit index_path
      #expect(page).to have_link I18n.t("gws/discussion.main_topic.name")

      text = "text-#{unique_id}"
      within "form" do
        fill_in "item[text]", with: text
        click_button I18n.t("ss.links.reply")
      end
      expect(page).to have_text(text)

      # edit
      within "#topic-#{item.id}" do
        click_on I18n.t('ss.links.edit')
      end

      text = "text-#{unique_id}"
      within "form#item-form" do
        fill_in "item[text]", with: text
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_text(text)

      # delete
      within "#topic-#{item.id}" do
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
