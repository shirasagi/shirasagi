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
        click_button "返信する"
      end
      expect(page).to have_text(text)

      # edit
      click_on "編集する"

      text = "text-#{unique_id}"
      within "form#item-form" do
        fill_in "item[text]", with: text
        click_button "保存"
      end
      expect(page).to have_text(text)

      # delete
      click_on "削除する"
      expect(page).to have_text(text)

      within "form" do
        click_button "削除"
      end

      expect(page).to have_no_text(text)
    end
  end
end
