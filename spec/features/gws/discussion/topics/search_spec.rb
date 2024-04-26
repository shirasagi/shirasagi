require 'spec_helper'

describe "gws_discussion_topics", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }

  let!(:forum1) { create :gws_discussion_forum }
  let!(:topic1_1) { create :gws_discussion_topic, forum: forum1, parent: forum1 }
  let!(:topic1_2) { create :gws_discussion_topic, forum: forum1, parent: forum1 }
  let!(:post1_1_1) { create :gws_discussion_post, forum: forum1, topic: topic1_1, parent: topic1_1 }
  let!(:post1_1_2) { create :gws_discussion_post, forum: forum1, topic: topic1_1, parent: topic1_1 }
  let!(:post1_2_1) { create :gws_discussion_post, forum: forum1, topic: topic1_2, parent: topic1_2 }
  let!(:post1_2_2) { create :gws_discussion_post, forum: forum1, topic: topic1_2, parent: topic1_2 }

  let!(:forum2) { create :gws_discussion_forum }
  let!(:topic2_1) { create :gws_discussion_topic, forum: forum2, parent: forum2 }
  let!(:post2_1_1) { create :gws_discussion_post, forum: forum2, topic: topic2_1, parent: topic2_1 }

  let!(:index_path) { gws_discussion_forum_topics_path(mode: '-', site: site, forum_id: forum1) }

  before { login_gws_user }

  it "#index" do
    visit index_path

    within ".gws-discussion-topic" do
      expect(page).to have_text(forum1.name)
    end
    within "\#topic-#{topic1_1.id}" do
      expect(page).to have_text(topic1_1.text)
      expect(page).to have_text(post1_1_1.text)
      expect(page).to have_text(post1_1_2.text)
    end
    within "\#topic-#{topic1_2.id}" do
      expect(page).to have_text(topic1_2.text)
      expect(page).to have_text(post1_2_1.text)
      expect(page).to have_text(post1_2_2.text)
    end

    within ".gws-discussion-topic" do
      within "form" do
        expect(page).to have_css("option", text: topic1_1.name)
        expect(page).to have_css("option", text: topic1_2.name)
        expect(page).to have_no_css("option", text: topic2_1.name)
        click_on I18n.t("ss.buttons.search")
      end
    end
    within ".gws-discussion" do
      expect(page).to have_css(".addon-body", text: topic1_1.text)
      expect(page).to have_css(".addon-body", text: topic1_2.text)
      expect(page).to have_css(".addon-body", text: post1_1_1.text)
      expect(page).to have_css(".addon-body", text: post1_2_1.text)
      expect(page).to have_css(".addon-body", text: post1_2_2.text)
    end
  end

  it "#index" do
    visit index_path

    within ".gws-discussion-topic" do
      within "form" do
        select topic1_1.name, from: "s[topic]"
        click_on I18n.t("ss.buttons.search")
      end
    end
    within ".gws-discussion" do
      expect(page).to have_css(".addon-body", text: topic1_1.text)
      expect(page).to have_no_css(".addon-body", text: topic1_2.text)
      expect(page).to have_css(".addon-body", text: post1_1_1.text)
      expect(page).to have_no_css(".addon-body", text: post1_2_1.text)
      expect(page).to have_no_css(".addon-body", text: post1_2_2.text)
    end

    within ".gws-discussion-topic" do
      within "form" do
        select topic1_2.name, from: "s[topic]"
        click_on I18n.t("ss.buttons.search")
      end
    end
    within ".gws-discussion" do
      expect(page).to have_no_css(".addon-body", text: topic1_1.text)
      expect(page).to have_css(".addon-body", text: topic1_2.text)
      expect(page).to have_no_css(".addon-body", text: post1_1_1.text)
      expect(page).to have_css(".addon-body", text: post1_2_1.text)
      expect(page).to have_css(".addon-body", text: post1_2_2.text)
    end
  end

  it "#index" do
    visit index_path

    within ".gws-discussion-topic" do
      within "form" do
        fill_in "s[body]", with: topic1_1.text
        click_on I18n.t("ss.buttons.search")
      end
    end
    within ".gws-discussion" do
      expect(page).to have_css(".addon-body", text: topic1_1.text)
      expect(page).to have_no_css(".addon-body", text: topic1_2.text)
      expect(page).to have_no_css(".addon-body", text: post1_1_1.text)
      expect(page).to have_no_css(".addon-body", text: post1_2_1.text)
      expect(page).to have_no_css(".addon-body", text: post1_2_2.text)
    end

    within ".gws-discussion-topic" do
      within "form" do
        fill_in "s[body]", with: post1_1_1.text
        click_on I18n.t("ss.buttons.search")
      end
    end
    within ".gws-discussion" do
      expect(page).to have_no_css(".addon-body", text: topic1_1.text)
      expect(page).to have_no_css(".addon-body", text: topic1_2.text)
      expect(page).to have_css(".addon-body", text: post1_1_1.text)
      expect(page).to have_no_css(".addon-body", text: post1_2_1.text)
      expect(page).to have_no_css(".addon-body", text: post1_2_2.text)
    end

    within ".gws-discussion-topic" do
      within "form" do
        fill_in "s[body]", with: post2_1_1.text
        click_on I18n.t("ss.buttons.search")
      end
    end
    within ".gws-discussion" do
      I18n.t("gws/discussion.notice.no_results")
    end
  end
end
