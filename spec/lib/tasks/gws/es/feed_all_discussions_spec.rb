require 'spec_helper'

describe Tasks::Gws::Es, dbscope: :example, es: true do
  before do
    @save = {}
    ENV.each do |key, value|
      @save[key.dup] = value.dup
    end

    # gws:es:ingest:init
    ::Gws::Elasticsearch.init_ingest(site: site)
    # gws:es:drop
    ::Gws::Elasticsearch.drop_index(site: site) rescue nil
    # gws:es:create_indexes
    ::Gws::Elasticsearch.create_index(site: site)
  end

  after do
    ENV.clear
    @save.each do |key, value|
      ENV[key] = value
    end
  end

  describe ".feed_all_discussions" do
    let!(:site) { create :gws_group, menu_elasticsearch_state: "show", elasticsearch_hosts: es_url }
    let!(:user) { create(:gws_user, group_ids: [ site.id ], gws_role_ids: gws_user.gws_role_ids) }
    let!(:file) do
      tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", binary: true, content_type: 'image/png')
    end
    let!(:forum) { create(:gws_discussion_forum, cur_site: site, cur_user: user, member_ids: [user.id]) }
    let!(:topic1) { create(:gws_discussion_topic, cur_site: site, cur_user: user, forum: forum, file_ids: [file.id]) }
    let!(:topic2) { create(:gws_discussion_topic, cur_site: site, cur_user: user, forum: forum) }
    let!(:post) { create(:gws_discussion_post, cur_site: site, cur_user: user, forum: forum, topic: topic1, parent: topic1) }

    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:deleted_forum) { create(:gws_discussion_forum, cur_site: site, cur_user: user, member_ids: [user.id], deleted: now) }
    let!(:deleted_topic) { create(:gws_discussion_topic, cur_site: site, cur_user: user, forum: forum, deleted: now) }
    let!(:deleted_post) do
      create(:gws_discussion_post, cur_site: site, cur_user: user, forum: forum, topic: topic1, parent: topic1, deleted: now)
    end

    before do
      ENV['site'] = site.name
    end

    it do
      expect { described_class.feed_all_discussions }.to output(include(post.name)).to_stdout

      ::Gws::Elasticsearch.refresh_index(site: site)
      site.elasticsearch_client.search(index: "g#{site.id}", size: 100, q: "*:*").tap do |es_docs|
        expect(es_docs["hits"]["hits"].length).to eq 4
        es_docs["hits"]["hits"][0].tap do |es_doc|
          expect(es_doc["_id"]).to eq "gws_discussion_posts-post-#{topic1.id}"
          source = es_doc["_source"]
          url = "/.g#{site.id}/discussion/-/forums/#{forum.id}/thread/topic#{topic1.id}/comments#comment-#{topic1.id}"
          expect(source['url']).to eq url
        end
        es_docs["hits"]["hits"][1].tap do |es_doc|
          expect(es_doc["_id"]).to eq "file-#{file.id}"
          source = es_doc["_source"]
          url = "/.g#{site.id}/discussion/-/forums/#{forum.id}/thread/topic#{topic1.id}/comments#file-#{file.id}"
          expect(source['url']).to eq url
        end
        es_docs["hits"]["hits"][2].tap do |es_doc|
          expect(es_doc["_id"]).to eq "gws_discussion_posts-post-#{topic2.id}"
          source = es_doc["_source"]
          url = "/.g#{site.id}/discussion/-/forums/#{forum.id}/thread/topic#{topic2.id}/comments#comment-#{topic2.id}"
          expect(source['url']).to eq url
        end
        es_docs["hits"]["hits"][3].tap do |es_doc|
          expect(es_doc["_id"]).to eq "gws_discussion_posts-post-#{post.id}"
          source = es_doc["_source"]
          url = "/.g#{site.id}/discussion/-/forums/#{forum.id}/thread/topic#{topic1.id}/comments#comment-#{post.id}"
          expect(source['url']).to eq url
        end
      end
    end
  end
end
