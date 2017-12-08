require 'spec_helper'

describe "gws_discussion_comments", type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let!(:site) { gws_site }
    let!(:item) { create :gws_discussion_topic }
    let!(:index_path) { gws_discussion_forum_topic_comments_path(site: site.id, forum_id: item.forum.id, topic_id: item.id) }

    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end
  end
end
