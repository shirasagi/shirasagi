require 'spec_helper'

describe "gws_discussion_topics", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:forum) { create :gws_discussion_forum }
  let!(:topic) { create :gws_discussion_topic, forum: forum, parent: forum }

  let!(:index_path) do
    gws_discussion_forum_thread_comments_path(mode: '-', site: site, forum_id: forum, topic_id: topic)
  end
  let!(:edit_path) do
    edit_gws_discussion_forum_thread_topic_path(mode: '-', site: site, forum_id: forum, id: topic)
  end
  let!(:delete_path) do
    delete_gws_discussion_forum_thread_topic_path(mode: '-', site: site, forum_id: forum, id: topic)
  end
  let!(:portal_path) do
    gws_discussion_forum_portal_path(mode: '-', site: site, forum_id: forum)
  end

  before { login_gws_user }

  it "#index" do
    visit index_path
    expect(current_path).not_to eq sns_login_path
  end

  it "#edit" do
    visit edit_path

    name = "modify-#{unique_id}"
    within "form#item-form" do
      fill_in "item[name]", with: name
      fill_in "item[text]", with: "text"
      click_button I18n.t('ss.buttons.save')
    end
    expect(current_path).to eq index_path
    wait_for_notice I18n.t("ss.notice.saved")
    within ".gws-discussion" do
      expect(page).to have_css(".addon-head", text: name)
    end
  end

  it "#delete" do
    visit delete_path
    within "form#item-form" do
      click_button I18n.t('ss.buttons.delete')
    end
    expect(current_path).to eq portal_path
    wait_for_notice I18n.t("ss.notice.deleted")
  end
end
