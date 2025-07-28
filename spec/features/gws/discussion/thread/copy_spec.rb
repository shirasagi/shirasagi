require 'spec_helper'

describe "gws_discussion_forum_thread", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:forum) { create :gws_discussion_forum }
  let!(:topic) { create :gws_discussion_topic, forum: forum, parent: forum }
  let!(:post1) { create :gws_discussion_post, forum: forum, topic: topic, parent: topic }
  let!(:post2) { create :gws_discussion_post, forum: forum, topic: topic, parent: topic, text: '# head', text_type: "markdown" }
  let!(:post3) { create :gws_discussion_post, forum: forum, topic: topic, parent: topic, text: '<s>html</s>', text_type: "cke" }
  let!(:post4) { create :gws_discussion_post, forum: forum, topic: topic, parent: topic, file_ids: [file.id] }

  let(:name) { "copy" }
  let(:file) { tmp_ss_file(user: user, contents: unique_id, basename: "text.txt") }

  let!(:copy_path) do
    copy_gws_discussion_forum_thread_topic_path(mode: '-', site: site, forum_id: forum, id: topic)
  end

  before { login_gws_user }

  it "#copy" do
    visit copy_path

    within "form#item-form" do
      fill_in "item[name]", with: name
      click_button I18n.t('ss.buttons.save')
    end
    wait_for_notice I18n.t("ss.notice.saved")

    # new_topic
    new_topic = Gws::Discussion::Topic.where(forum_id: forum.id, name: name).first
    expect(new_topic.forum_id).to eq forum.id
    expect(new_topic.parent_id).to eq forum.id
    expect(new_topic.topic_id).to eq nil
    expect(new_topic.name).to eq name
    expect(new_topic.contributor_name).to eq topic.contributor_name
    expect(new_topic.text).to eq topic.text
    expect(new_topic.text_type).to eq topic.text_type
    expect(new_topic.file_ids).to be_blank

    # new_posts
    new_posts = new_topic.children.order(id: 1).to_a
    expect(new_posts.size).to eq 4

    new_post1 = new_posts[0]
    expect(new_post1.forum.id).to eq forum.id
    expect(new_post1.topic.id).to eq new_topic.id
    expect(new_post1.topic.id).to eq new_topic.id
    expect(new_post1.name).to eq name
    expect(new_post1.contributor_name).to eq post1.contributor_name
    expect(new_post1.text).to eq post1.text
    expect(new_post1.text_type).to eq post1.text_type
    expect(new_post1.file_ids).to be_blank

    new_post2 = new_posts[1]
    expect(new_post2.forum.id).to eq forum.id
    expect(new_post2.topic.id).to eq new_topic.id
    expect(new_post2.topic.id).to eq new_topic.id
    expect(new_post2.name).to eq name
    expect(new_post2.contributor_name).to eq post2.contributor_name
    expect(new_post2.text).to eq post2.text
    expect(new_post2.text_type).to eq post2.text_type
    expect(new_post2.file_ids).to be_blank

    new_post3 = new_posts[2]
    expect(new_post3.forum.id).to eq forum.id
    expect(new_post3.topic.id).to eq new_topic.id
    expect(new_post3.topic.id).to eq new_topic.id
    expect(new_post3.name).to eq name
    expect(new_post3.contributor_name).to eq post3.contributor_name
    expect(new_post3.text).to eq post3.text
    expect(new_post3.text_type).to eq post3.text_type
    expect(new_post3.file_ids).to be_blank

    new_post4 = new_posts[3]
    expect(new_post4.forum.id).to eq forum.id
    expect(new_post4.topic.id).to eq new_topic.id
    expect(new_post4.topic.id).to eq new_topic.id
    expect(new_post4.name).to eq name
    expect(new_post4.contributor_name).to eq post4.contributor_name
    expect(new_post4.text).to eq post4.text
    expect(new_post4.text_type).to eq post4.text_type
    expect(new_post4.files.size).to eq 1

    new_file = new_post4.files.first
    expect(new_file.id).not_to eq file.id
    expect(new_file.name).to eq file.name
    expect(::File.read(new_file.path)).to eq ::File.read(file.path)
  end
end
