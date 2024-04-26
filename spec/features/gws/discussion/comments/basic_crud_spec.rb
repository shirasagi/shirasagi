require 'spec_helper'

describe "gws_discussion_comments", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:forum) { create :gws_discussion_forum }
  let!(:topic) { create :gws_discussion_topic, forum: forum, parent: forum }

  let!(:index_path) { gws_discussion_forum_topic_comments_path(mode: '-', site: site, forum_id: forum, topic_id: topic) }

  before { login_gws_user }

  it "#index" do
    visit index_path
    within "#topic-#{topic.id}" do
      expect(page).to have_link(topic.name)
    end
  end
end
