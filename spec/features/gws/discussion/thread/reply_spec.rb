require 'spec_helper'

describe "gws_discussion_forum_thread", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:forum) { create :gws_discussion_forum }
  let!(:topic) { create :gws_discussion_topic, forum: forum, parent: forum }

  let!(:index_path) do
    gws_discussion_forum_thread_comments_path(mode: '-', site: site, forum_id: forum, topic_id: topic)
  end

  before { login_gws_user }

  it "#reply" do
    visit index_path
    within "#topic-#{topic.id}" do
      expect(page).to have_link(topic.name)
    end

    text = "text-#{unique_id}"
    within "form.reply" do
      fill_in "item[text]", with: text
      click_button I18n.t("ss.links.reply")
    end
    expect(current_path).to eq index_path
    wait_for_notice I18n.t("ss.notice.saved")
    expect(page).to have_text(text)

    # edit
    within "#topic-#{topic.id}" do
      click_on I18n.t('ss.links.edit')
    end

    text = "text-#{unique_id}"
    within "form#item-form" do
      fill_in "item[text]", with: text
      click_button I18n.t('ss.buttons.save')
    end
    expect(current_path).to eq index_path
    wait_for_notice I18n.t("ss.notice.saved")
    expect(page).to have_text(text)

    # delete
    within "#topic-#{topic.id}" do
      click_on I18n.t('ss.links.delete')
    end
    expect(page).to have_text(text)

    within "form#item-form" do
      click_button I18n.t('ss.buttons.delete')
    end
    expect(current_path).to eq index_path
    wait_for_notice I18n.t("ss.notice.deleted")
    expect(page).to have_no_text(text)
  end
end
