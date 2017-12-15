require 'spec_helper'

describe "gws_discussion_topics", type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let!(:site) { gws_site }
    let!(:item) { create :gws_discussion_topic }
    let!(:index_path) { gws_discussion_forum_topics_path(site: site.id, forum_id: item.forum.id) }
    let!(:new_path) { new_gws_discussion_forum_topic_path(site: site.id, forum_id: item.forum.id) }
    let!(:show_path) { gws_discussion_forum_topic_path(site: site.id, forum_id: item.forum.id, id: item.id) }
    let!(:edit_path) { edit_gws_discussion_forum_topic_path(site: site.id, forum_id: item.forum.id, id: item.id) }
    let!(:delete_path) { delete_gws_discussion_forum_topic_path(site: site.id, forum_id: item.forum.id, id: item.id) }

    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path

      name = "name-#{unique_id}"
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[text]", with: "text"
        click_button "保存"
      end
      expect(first('#addon-basic')).to have_text(name)
    end

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path

      name = "modify-#{unique_id}"
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[text]", with: "text"
        click_button "保存"
      end
      expect(first('#addon-basic')).to have_text(name)
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end
  end
end
