require 'spec_helper'

describe "gws_discussion_topics", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:forum) { create :gws_discussion_forum }
  let!(:topic) { create :gws_discussion_topic, forum: forum, parent: forum }
  let!(:copy_path) { copy_gws_discussion_forum_topic_path(mode: '-', site: site, forum_id: forum, id: topic) }

  before { login_gws_user }

  it "#copy" do
    visit copy_path

    within "form#item-form" do
      fill_in "item[name]", with: "copy"
      click_button I18n.t('ss.buttons.save')
    end
    wait_for_notice I18n.t("ss.notice.saved")

    item = Gws::Discussion::Topic.where(forum_id: forum.id, name: "copy").first
    expect(item).to be_present
  end
end
