require 'spec_helper'

describe "gws_discussion_forums", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:forum) { create :gws_discussion_forum }
  let!(:topic1) { create :gws_discussion_topic, forum: forum, parent: forum }
  let!(:topic2) { create :gws_discussion_topic, forum: forum, parent: forum }
  let!(:post1_1) { create :gws_discussion_post, forum: forum, topic: topic1, parent: topic1 }
  let!(:post1_2) { create :gws_discussion_post, forum: forum, topic: topic1, parent: topic1, file_ids: [file1.id] }
  let!(:post2_1) { create :gws_discussion_post, forum: forum, topic: topic2, parent: topic2 }
  let!(:post2_2) { create :gws_discussion_post, forum: forum, topic: topic2, parent: topic2, file_ids: [file2.id] }

  let(:name) { "copy" }
  let!(:copy_path) { copy_gws_discussion_forum_path(mode: '-', site: site, id: forum) }

  let(:file1) { tmp_ss_file(user: user, contents: unique_id, basename: "text.txt") }
  let(:file2) { tmp_ss_file(user: user, contents: unique_id, basename: "text.txt") }

  before { login_gws_user }

  it "#copy" do
    visit copy_path

    within "form#item-form" do
      fill_in "item[name]", with: "copy"
      click_button I18n.t('ss.buttons.save')
    end

    # new forum
    new_forum = Gws::Discussion::Forum.where(name: "copy").first
    expect(new_forum).to be_present

    # new_topics
    new_topics = new_forum.children.order(id: 1).to_a
    expect(new_topics.size).to eq 2

    new_topic1 = new_topics[0]
    expect(new_topic1.forum_id).to eq new_forum.id
    expect(new_topic1.parent_id).to eq new_forum.id
    expect(new_topic1.topic_id).to eq nil
    expect(new_topic1.name).to eq topic1.name
    expect(new_topic1.contributor_name).to eq topic1.contributor_name
    expect(new_topic1.text).to eq topic1.text
    expect(new_topic1.text_type).to eq topic1.text_type
    expect(new_topic1.file_ids).to be_blank

    new_topic2 = new_topics[1]
    expect(new_topic2.forum_id).to eq new_forum.id
    expect(new_topic2.parent_id).to eq new_forum.id
    expect(new_topic2.topic_id).to eq nil
    expect(new_topic2.name).to eq topic2.name
    expect(new_topic2.contributor_name).to eq topic2.contributor_name
    expect(new_topic2.text).to eq topic2.text
    expect(new_topic2.text_type).to eq topic2.text_type
    expect(new_topic2.file_ids).to be_blank

    # new_posts
    new_posts = new_topic1.children.order(id: 1).to_a
    expect(new_posts.size).to eq 2

    new_post1_1 = new_posts[0]
    expect(new_post1_1.forum.id).to eq new_forum.id
    expect(new_post1_1.topic.id).to eq new_topic1.id
    expect(new_post1_1.topic.id).to eq new_topic1.id
    expect(new_post1_1.name).to eq post1_1.name
    expect(new_post1_1.contributor_name).to eq post1_1.contributor_name
    expect(new_post1_1.text).to eq post1_1.text
    expect(new_post1_1.text_type).to eq post1_1.text_type
    expect(new_post1_1.file_ids).to be_blank

    new_post1_2 = new_posts[1]
    expect(new_post1_2.forum.id).to eq new_forum.id
    expect(new_post1_2.topic.id).to eq new_topic1.id
    expect(new_post1_2.topic.id).to eq new_topic1.id
    expect(new_post1_2.name).to eq post1_2.name
    expect(new_post1_2.contributor_name).to eq post1_2.contributor_name
    expect(new_post1_2.text).to eq post1_2.text
    expect(new_post1_2.text_type).to eq post1_2.text_type
    expect(new_post1_2.files.size).to eq 1

    new_file1 = new_post1_2.files.first
    expect(new_file1.id).not_to eq file1.id
    expect(new_file1.name).to eq file1.name
    expect(::File.read(new_file1.path)).to eq ::File.read(file1.path)

    new_posts = new_topic2.children.order(id: 1).to_a
    expect(new_posts.size).to eq 2

    new_post2_1 = new_posts[0]
    expect(new_post2_1.forum.id).to eq new_forum.id
    expect(new_post2_1.topic.id).to eq new_topic2.id
    expect(new_post2_1.topic.id).to eq new_topic2.id
    expect(new_post2_1.name).to eq post2_1.name
    expect(new_post2_1.contributor_name).to eq post2_1.contributor_name
    expect(new_post2_1.text).to eq post2_1.text
    expect(new_post2_1.text_type).to eq post2_1.text_type
    expect(new_post2_1.file_ids).to be_blank

    new_post2_2 = new_posts[1]
    expect(new_post2_2.forum.id).to eq new_forum.id
    expect(new_post2_2.topic.id).to eq new_topic2.id
    expect(new_post2_2.topic.id).to eq new_topic2.id
    expect(new_post2_2.name).to eq post2_2.name
    expect(new_post2_2.contributor_name).to eq post2_2.contributor_name
    expect(new_post2_2.text).to eq post2_2.text
    expect(new_post2_2.text_type).to eq post2_2.text_type
    expect(new_post2_2.files.size).to eq 1

    new_file2 = new_post2_2.files.first
    expect(new_file2.id).not_to eq file1.id
    expect(new_file2.name).to eq file1.name
    expect(::File.read(new_file2.path)).to eq ::File.read(file2.path)
  end
end
