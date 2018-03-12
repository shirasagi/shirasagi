require 'spec_helper'

describe "gws_discussion_topics_notify_message", type: :feature, dbscope: :example do
  context "notify_message", js: true do
    let!(:site) { gws_site }
    let!(:discussion_member) { create :gws_user }
    let!(:forum1) { create :gws_discussion_forum, notify_state: "disabled" }
    let!(:forum2) { create :gws_discussion_forum, notify_state: "enabled" }
    let!(:forum3) { create :gws_discussion_forum, notify_state: "enabled", state: "closed" }

    let!(:new_path1) { new_gws_discussion_forum_topic_path(site: site.id, forum_id: forum1.id) }
    let!(:new_path2) { new_gws_discussion_forum_topic_path(site: site.id, forum_id: forum2.id) }
    let!(:new_path3) { new_gws_discussion_forum_topic_path(site: site.id, forum_id: forum3.id) }

    before { login_gws_user }
    before do
      forum1.add_to_set(member_ids: discussion_member.id)
      forum2.add_to_set(member_ids: discussion_member.id)
      forum3.add_to_set(member_ids: discussion_member.id)
    end

    it "with disabled forum" do
      visit new_path1

      within "form#item-form" do
        fill_in "item[name]", with: "name"
        fill_in "item[text]", with: "text"
        click_button "保存"
      end

      item = Gws::Memo::Notice.where(subject: /#{forum1.name}/).first
      expect(item).to be_nil
    end

    it "with enabled forum" do
      visit new_path2

      within "form#item-form" do
        fill_in "item[name]", with: "name"
        fill_in "item[text]", with: "text"
        click_button "保存"
      end

      item = Gws::Memo::Notice.where(subject: /#{forum2.name}/).first
      expect(item).not_to be_nil
    end

    it "with enabled closed" do
      visit new_path3

      within "form#item-form" do
        fill_in "item[name]", with: "name"
        fill_in "item[text]", with: "text"
        click_button "保存"
      end

      item = Gws::Memo::Notice.where(subject: /#{forum3.name}/).first
      expect(item).to be_nil
    end
  end
end
