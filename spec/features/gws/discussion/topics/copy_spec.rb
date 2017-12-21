require 'spec_helper'

describe "gws_discussion_topics", type: :feature, dbscope: :example do
  context "copy", js: true do
    let!(:site) { gws_site }
    let!(:item) { create :gws_discussion_topic }
    let!(:copy_path) { copy_gws_discussion_forum_topic_path(site: site.id, forum_id: item.forum.id, id: item.id) }

    before { login_gws_user }

    it "#copy" do
      visit copy_path

      within "form#item-form" do
        fill_in "item[name]", with: "copy"
        click_button "保存"
      end

      topic = Gws::Discussion::Topic.where(forum_id: item.forum.id, name: "copy").first
      expect(topic).not_to be nil
    end
  end
end
