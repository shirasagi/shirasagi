require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20240430000000_discussion_post_body_text.rb")

RSpec.describe SS::Migration20240430000000, dbscope: :example do
  let!(:forum) { create :gws_discussion_forum }
  let!(:topic) { create :gws_discussion_topic, forum: forum, parent: forum }
  let!(:post) { create :gws_discussion_post, forum: forum, topic: topic, parent: topic }

  it do
    text1 = topic.body_text
    text2 = post.body_text

    topic.unset(:body_text)
    post.unset(:body_text)
    topic.reload
    post.reload

    expect(topic.body_text).to eq nil
    expect(post.body_text).to eq nil

    described_class.new.change
    topic.reload
    post.reload

    expect(topic.body_text).to eq text1
    expect(post.body_text).to eq text2
  end
end
